package Crypt::Age::Simple::Encrypt;
use v5.24;
use Moo;
use English qw< -no_match_vars >;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed >;

use Crypt::Age::Header;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::AuthEnc::ChaCha20Poly1305;
use Crypt::PRNG qw(random_bytes);
use Crypt::Age::Simple::Buffer;
use Crypt::Age::Simple::Common qw<
   :constants
   age_base64_multiline
   age_primitives_make_nonce
   age_scrypt_wrap_key
   buffer
>;

use constant {
   DEFAULT_WORK_FACTOR => 18,
   SALT_SIZE => 16,
};

use namespace::clean;

has _input_buffer   => (is => 'ro');
has _counter => (is => 'rw', default => 0);
has _last_sent => (is => 'rw', default => 0, reader => 'is_exhausted');
has _payload_key => (is => 'rw', default => undef);

has recipients => (is => 'ro', required => 1);
has is_error => (is => 'rwp', default => 0, init_arg => undef);
has is_complete => (is => 'rwp', default => 0, init_arg => undef);

around BUILDARGS => sub ($orig, $class, @args) {
   unshift @args, 'recipients' if @args % 2 && ref($args[0]) ne 'HASH';
   my %input_args = @args == 1 ? $args[0]->%* : @args;

   my %args;
   for my $key (qw< recipients >) {
      $args{$key} = $input_args{$key} if defined($input_args{$key});
   }

   # we accept taking an input buffer, e.g. if we already have the whole
   # thing in memory and we don't want to be passing it over and over (the
   # offset should help us to this regard)
   if (defined($input_args{input})) {
      my $input = ref($args{input}) ? $args{input} : \$args{input};
      $args{_input_buffer} = blessed($input) ? $input
         : Crypt::Age::Simple::Buffer->new(buffers => $input);
   }
   else {
      $args{_input_buffer} = Crypt::Age::Simple::Buffer->new;
   }

   return $class->$orig(%args);
};

sub get_chunks ($self, $n = undef) {
   ouch 400, 'object is in error state' if $self->is_error;
   return [] if $self->is_exhausted;  # already sent the last chunk...

   $self->_set_is_error(1);
   my $retval = $self->_get_chunks($n);
   $self->_set_is_error(0);

   return $retval;
}

sub _get_chunks ($self, $n) {
   $n ||= -1;
   my @retval;

   my $payload_key = $self->_payload_key;
   if (! defined($payload_key)) {
      (my $chunkref, $payload_key) = $self->_kickstart;
      $self->_payload_key($payload_key);
      push @retval, $chunkref;
      --$n;
   }

   my $is_complete = $self->is_complete;
   my $counter = $self->_counter;
   my $buffer = $self->_input_buffer;
   my $available_bytes = $buffer->available_bytes;

   while ($n != 0 && ($available_bytes > 0 || $is_complete)) {
      my ($chunkref, $is_final);
      if ($available_bytes > CHUNK_SIZE) {
         $is_final = 0;
         $chunkref = $buffer->get_bytes(CHUNK_SIZE);
         $available_bytes -= CHUNK_SIZE;
      }
      elsif ($is_complete) {
         $is_final = 1;
         $chunkref = $available_bytes > 0 ? $buffer->get_bytes : \'';
         $available_bytes = 0;
      }
      else { last }

      my $nonce = age_primitives_make_nonce($counter, $is_final);
      my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($payload_key, $nonce);
      my $ciphertext = $ae->encrypt_add($$chunkref);
      my $tag = $ae->encrypt_done;
      $ciphertext .= $tag;
      push @retval, \$ciphertext;

      last if $is_final;
      ++$counter;
      --$n;
   }
   $self->_counter($counter);

   return \@retval;
}

sub pump ($self, $input) {
   ouch 400, 'object is in error state' if $self->is_error;
   ouch 400, 'cannot pump() after complete()' if $self->is_complete;

   # acquire new data in the input buffer
   $self->_input_buffer->put(ref($input) ? $input : \$input);

   return $self; # allow chaining
}

sub finish ($self) {
   ouch 400, 'object is in error state' if $self->is_error;
   $self->_set_is_complete(1);
   return $self; # allow chaining
}

sub _firstchunk_scrypt ($self, $file_key, $input) {
   my ($password, $Nlog2)
      = ref($input) eq 'HASH' ? $input->@{qw< password work_factor >}
                              : ($input, DEFAULT_WORK_FACTOR);

   my $salt = random_bytes(SALT_SIZE);
   my $wrap_key = age_scrypt_wrap_key($password, $salt, $Nlog2);
   my $body = Crypt::Age::Primitives->wrap_file_key($wrap_key, $file_key);

   # create header
   my $salt64 = Crypt::Age::Stanza::encode_base64_no_padding($salt);
   my $stanza_header = "-> scrypt $salt64 $Nlog2";
   my $stanza_body   = age_base64_multiline($body);
   my $header
      = join("\x{0a}", VERSION_LINE, $stanza_header, $stanza_body, '---');
   my $mac
      = Crypt::Age::Primitives->compute_header_mac($file_key, $header);
   my $mac64 = Crypt::Age::Stanza::encode_base64_no_padding($mac);
   return $header . "\x{20}" . $mac64 . "\x{0a}";
}

sub _kickstart ($self) {
   my $recipients = $self->recipients;
   my $file_key = Crypt::Age::Primitives->generate_file_key;

   # generate the header
   my $chunkref;
   my $reftype = ref($recipients);
   if ($reftype eq 'CODE') {
      $chunkref = $recipients->($file_key);
   }
   else {
      my ($type, $args) = $reftype eq 'HASH' ? $recipients->%*
         : $reftype eq 'ARRAY' ? ( X25519 => $recipients )
         : $reftype ? ouch 400, 'cannot handle this kind of reference'
         : ( scrypt => $recipients );
      my $chunk;
      if (uc($type) eq 'X25519') {
         my $header = Crypt::Age::Header->create($file_key, $args);
         $chunk = $header->to_string;
      }
      elsif ($type eq 'scrypt') {
         $chunk = $self->_firstchunk_scrypt($file_key, $args);
      }
      else {
         ouch 400, "unknown type <$type>";
      }
      ouch 400, 'cannot use the recipient(s)' unless defined($chunk);
      $chunkref = \$chunk;
   }

   my $nonce = Crypt::Age::Primitives->generate_payload_nonce;
   $$chunkref .= $nonce;

   # generate the payload key
   my $payload_key
      = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);

   return ($chunkref, $payload_key);
}

1;
