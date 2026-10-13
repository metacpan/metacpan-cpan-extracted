package Crypt::Age::Simple::Decrypt;
use v5.24;
use Moo;
use English qw< -no_match_vars >;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed >;

use Crypt::Age::Header;
use Crypt::Age::Primitives;
use Crypt::AuthEnc::ChaCha20Poly1305;
use Crypt::Age::Simple::Buffer;
use Crypt::Age::Simple::Common qw<
   :constants
   age_primitives_make_nonce
   age_scrypt_unwrap_file_key
   buffer
>;

use constant MAX_HEADER_SIZE => 64 * 1024; # it's actually the _DEFAULT..._

# end = "--- " 43base64char LF
use constant MAC_LINE_SIZE => 4 + 43 + 1;

use namespace::clean;

has _input_buffer   => (is => 'ro');
has _header_bytes => (
   is => 'rw',
   default => sub {
      my $bytes = '';
      return \$bytes;
   },
);
has _payload_key => (is => 'rw', default => undef);
has _counter => (is => 'rw', default => 0);
has _last_sent => (is => 'rw', default => 0, reader => 'is_exhausted');
has _header => (is => 'rw');

has max_header_size => (is => 'ro', default => MAX_HEADER_SIZE);
has identity => (is => 'ro', required => 1); # free-formish
has is_error => (is => 'rwp', default => 0, init_arg => undef);
has is_complete => (is => 'rwp', default => 0, init_arg => undef);

around BUILDARGS => sub ($orig, $class, @args) {
   unshift @args, 'identity' if @args % 2 && ref($args[0]) ne 'HASH';
   my %input_args = @args == 1 ? $args[0]->%* : @args;

   my %args;
   for my $key (qw< identity max_header_size >) {
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

# $n = undef means everything that can be taken
sub get_chunks ($self, $n = undef) {
   ouch 400, 'object is in error state' if $self->is_error;
   return [] if $self->is_exhausted;  # already sent the last chunk...
   my $payload_key = $self->_payload_key or return [];

   $self->_set_is_error(1);
   my $retval = $self->_get_chunks($n);
   $self->_set_is_error(0);

   return $retval;
}

sub has_header ($self) { return defined($self->_header) }

sub header ($self) { return $self->_header }

sub pump ($self, $input) {
   ouch 400, 'object is in error state' if $self->is_error;
   ouch 400, 'cannot pump() after complete()' if $self->is_complete;

   # acquire new data in the input buffer
   $self->_input_buffer->put(ref($input) ? $input : \$input);

   # use some of the data if possible
   if (! defined($self->_payload_key)) {
      $self->_set_is_error(1);
      $self->_attempt_parse_header unless defined($self->_header);
      $self->_attempt_set_payload_key  if defined($self->_header);;
      $self->_set_is_error(0);
   }

   return $self; # allow chaining
}

sub finish ($self) {
   ouch 400, 'object is in error state' if $self->is_error;
   $self->_set_is_complete(1);
   return $self; # allow chaining
}

# Accumulate bytes up to no more than $self->max_header_size and look for
# the MAC line inside it
sub _attempt_parse_header ($self) {
   return if defined($self->_header); # parse done!

   my $bytesref = $self->_header_bytes;
   my $max_header_size = $self->max_header_size;
   my $n_acceptable = $max_header_size - length($$bytesref);
   ouch 500, 'not acceptable bytes in not acceptable stage'
      if $n_acceptable <= 0;

   # get new data
   my $buffer = $self->_input_buffer;
   my $available_bytes = $buffer->available_bytes;
   return unless $available_bytes > 0; # nothing available yet..
   my $part = $buffer->get_bytes($n_acceptable);

   # we already took a look at the data already present and did
   # *NOT* find what we're after. Note that using length(...) as-is
   # without offsetting 1 is the correct way to do it --we must
   # restart the search from the first point that we could not
   # properly test before
   my $idx_offset = length($$bytesref) - MAC_LINE_SIZE;
   $idx_offset = 0 if $idx_offset < 0;

   # append and restart the search from the offset
   $$bytesref .= $$part;
   my $idx = index($$bytesref, "\x{0a}---\x{20}", $idx_offset);

   my $len = length($$bytesref);
   ouch 400, 'no valid header within the acceptable limit'
      if ($idx < 0  && $len >= $max_header_size)
      || ($idx >= 0 && $idx + MAC_LINE_SIZE + 1 > $max_header_size);

   return if $idx < 0; # mac line not found yet

   # mac line start found, but not enough data to parse yet
   return if $idx >= 0 && $idx + MAC_LINE_SIZE + 1 > $len;

   # we have enough data for parsing here
   my $offset = 0;
   my $header = Crypt::Age::Header->parse($bytesref, \$offset);
   $self->_header($header);

   # we might have residual data to give back to the input buffer
   $buffer->give_back($bytesref, $offset) if $offset < $len;

   # we don't care about the buffer any more
   $self->_header_bytes(undef);

   return;
}

sub _attempt_set_payload_key ($self) {
   return if defined($self->_payload_key); # payload_key already set

   # sanity check
   defined(my $header = $self->header)
      or ouch 500, 'trying to set the payload key without headers...';

   # we need the buffer to have *at least* NONCE_SIZE bytes to operate in
   # this sub, otherwise we have to wait for more data
   my $buffer = $self->_input_buffer;
   my $available_bytes = $buffer->available_bytes;
   return unless $available_bytes >= NONCE_SIZE; # not ready yet..

   # this might be done immediately after parsing the header *but* we
   # defer it to when it's really needed, i.e. here
   defined(my $file_key = $self->_get_file_key)
      or ouch 400, 'cannot get the file key... wrong identity?';
   $header->verify_mac($file_key)
      or ouch 500, 'MAC verification failed...';

   # OK, we can read the nonce and calculate the payload key now
   my $nonce = $buffer->get_bytes_exactly(NONCE_SIZE)->$*;
   my $payload_key
      = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);
   $self->_payload_key($payload_key);

   return;
}

sub _get_file_key_scrypt ($self, $password) {
   my $header = $self->header;
   my @stanzas = $header->stanzas->@*;
   ouch 400, 'header not for scrypt' if @stanzas != 1;
   ouch 400, 'header stanza not of scrypt type'
      if $stanzas[0]->type ne 'scrypt';

   my $file_key = age_scrypt_unwrap_file_key($stanzas[0], $password)
      or ouch 400, 'undefined file key... wrong password?';
   $header->verify_mac($file_key)
      or ouch 400, 'MAC verification failed... wrong password?';

   return $file_key;
}

sub _get_file_key ($self) {
   my $identity = $self->identity;
   my $header = $self->header;

   my $reftype = ref($identity);
   return $identity->($header) if $reftype eq 'CODE';

   my $file_key;
   my ($type, $args) = $reftype eq 'HASH' ? $identity->%*
      : $reftype eq 'ARRAY' ? ( X25519 => $identity )
      : $reftype ? ouch 400, 'cannot handle this kind of reference'
      : ( scrypt => $identity );
   if (uc($type) eq 'X25519') {
      my @ids = ref($args) eq 'ARRAY' ? $args->@* : ($args);
      $file_key = $header->unwrap_file_key(\@ids);
   }
   elsif ($type eq 'scrypt') {
      $file_key = $self->_get_file_key_scrypt($args);
   }
   else {
      ouch 400, "unknown type <$type>";
   }
   ouch 500, 'cannot use the identity' unless defined($file_key);

   return $file_key;
}

sub _get_chunks ($self, $n) {
   my $is_complete = $self->is_complete;
   my $buffer = $self->_input_buffer;
   my $counter = $self->_counter;
   my $payload_key = $self->_payload_key;

   my $available_bytes = $buffer->available_bytes;
   if ($is_complete && $available_bytes == 0) {
      if ($counter == 0) {
         $self->_last_sent(1);
         return [ \'' ];
      }

      # this case should not arguably ever happen, anyway...
      ouch 400, 'no final chunk seen (is it even possible?!?)';
   }

   my @retval;
   $n ||= -1;
   while ($n != 0 && $available_bytes > 0) {
      my ($tag, $chunk, $is_final);
      if ($available_bytes > TAG_SIZE + CHUNK_SIZE) { # surely not final
         $is_final = 0;
         $chunk = $buffer->get_bytes(CHUNK_SIZE);
         $available_bytes -= CHUNK_SIZE;
         $tag = $buffer->get_bytes(TAG_SIZE);
         $available_bytes -= TAG_SIZE;
      }
      elsif ($is_complete) { # almost anything goes
         ouch 400, q{not enough data for last chunk's TAG}
            if $available_bytes < TAG_SIZE;
         $is_final = 1;
         $chunk = $buffer->get_bytes($available_bytes - TAG_SIZE);
         $tag = $buffer->get_bytes(TAG_SIZE);
         $available_bytes = 0;
      }
      else {
         last;  # not enough bytes to attempt a decryption
      }

      my $nonce = age_primitives_make_nonce($counter, $is_final);
      my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($payload_key, $nonce);
      my $plaintext = $ae->decrypt_add($$chunk);
      ouch 400, "Payload authentication failed at chunk $counter"
         unless $ae->decrypt_done($$tag);
      $counter++;

      push @retval, \$plaintext;
      $self->_last_sent(1) if $is_final;

      --$n;
   }

   $self->_counter($counter);

   return \@retval;
}

1;
