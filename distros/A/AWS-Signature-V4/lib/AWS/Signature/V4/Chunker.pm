package AWS::Signature::V4::Chunker;
use v5.24;
use Moo;
use AWS::Signature::V4::Error qw< fail shown >;
use Digest::SHA qw< sha256_hex hmac_sha256_hex >;
use experimental qw< signatures >;
use namespace::clean;

use AWS::Signature::V4::Checksum ();

# The chunker is created by AWS::Signature::V4::sign(), which knows all of
# this: the arguments are not a public interface.
has signed        => (is => 'ro', required => 1);
has amzdate       => (is => 'ro');
has scope         => (is => 'ro');

# The signing key, for signed chunks only, can sign any request for the same
# service, region and day: it is kept in a closure, so that no accessor gives
# it back and dumping the object does not show it. The closure can still sign
# with it, so the chunker is no safer to share than the signer.
has _mac => (
   is       => 'ro',
   init_arg => 'key',
   coerce   => sub ($key) {
      ref $key eq 'CODE' ? $key : sub ($data) { hmac_sha256_hex($data, $key) };
   },
);

# signature of the previous chunk: the chain must not be changed from outside
has _previous => (is => 'rw', init_arg => 'previous');
has expected      => (is => 'ro', required => 1);    # declared size of the data
has checksum      => (is => 'ro');    # name of the built-in checksum, if any
has trailer_names => (is => 'ro', default => sub { [] });

has _seen => (is => 'rw', init_arg => undef, default => 0);
has _done => (is => 'rw', init_arg => undef, default => 0);
has _sum  => (is => 'lazy', init_arg => undef);

sub BUILD ($self, $args) {
   fail 500, 'signed chunks need a "key"' if $self->signed && !$self->_mac;
   return;
}

sub _build__sum ($self) {
   my $algo = $self->checksum;
   return defined $algo ? AWS::Signature::V4::Checksum->new($algo) : undef;
}

sub _sign ($self, $data_ref) {
   my $string_to_sign = join "\n", 'AWS4-HMAC-SHA256-PAYLOAD',
      $self->amzdate, $self->scope, $self->_previous,
      sha256_hex(''), sha256_hex($$data_ref);
   return $self->_previous($self->_mac->($string_to_sign));
}

# encoded chunk for the data (a byte string or a reference to one)
sub chunk ($self, $data) {
   fail 400, 'chunker already finished' if $self->_done;
   fail 400, 'chunk must be a byte string or a reference to one'
      if ref $data && ref $data ne 'SCALAR';
   my $ref = ref $data ? $data : \$data;
   my $len = length($$ref) // 0;
   fail 400, 'empty chunk: call finish() to terminate the stream' unless $len;
   _is_bytes($ref) or fail 400, 'chunk must be a byte string: encode characters first';
   my $seen = $self->_seen + $len;
   fail 400, "more data than the declared @{[ $self->expected ]} bytes"
      if $seen > $self->expected;
   $self->_seen($seen);
   $self->_sum->add($ref) if $self->_sum;
   my $head = $self->signed
      ? sprintf('%x;chunk-signature=%s', $len, $self->_sign($ref))
      : sprintf('%x', $len);
   return "$head\r\n" . $$ref . "\r\n";
}

# the final, empty chunk, followed by the trailers if any; the values of the
# trailers that were declared with "trailers" are passed by name, in any case
sub finish ($self, %given) {
   fail 400, 'chunker already finished' if $self->_done;
   fail 400, "got @{[ $self->_seen ]} bytes instead of the declared @{[ $self->expected ]}"
      if $self->_seen != $self->expected;
   my %values;
   for my $name (sort keys %given) {
      fail 400, "trailer '" . shown(lc $name) . "' given twice" if exists $values{lc $name};
      $values{lc $name} = $given{$name};
   }

   # all checks come before the checksum is taken, which is not repeatable,
   # and before the chain of signatures moves on: after an error, the chunker
   # is as it was
   my $computed = $self->_sum ? 'x-amz-checksum-' . $self->checksum : undef;
   my @pairs;
   for my $name ($self->trailer_names->@*) {
      my $value;
      if (defined $computed && $name eq $computed) {
         fail 400, "trailer '$name' is computed, not to be given" if exists $values{$name};
      }
      else {
         $value = delete $values{$name} // fail 400, "missing value for trailer '$name'";
         fail 400, "invalid value for trailer '$name': a byte string, no CR, LF or NUL"
            if ref $value || $value =~ m{[\r\n\0]} || !_is_bytes(\$value);
         utf8::downgrade($value);
      }
      push @pairs, [$name, $value];
   }
   fail 400, 'undeclared trailers: ' . join(', ', map { shown($_) } sort keys %values)
      if %values;
   my @lines = map { "$_->[0]:" . ($_->[1] // $self->_sum->base64) } @pairs;
   my $trailers = join '', map { "$_\r\n" } @lines;

   my $body;
   if (!$self->signed) {
      $body = "0\r\n$trailers\r\n";
   }
   elsif (!@lines) {
      $body = "0;chunk-signature=@{[ $self->_sign(\'') ]}\r\n\r\n";
   }
   else {
      my $sig = $self->_sign(\'');
      my $string_to_sign = join "\n", 'AWS4-HMAC-SHA256-TRAILER',
         $self->amzdate, $self->scope, $self->_previous,
         sha256_hex(join '', map { "$_\n" } @lines);
      my $tsig = $self->_mac->($string_to_sign);
      $body = "0;chunk-signature=$sig\r\n${trailers}x-amz-trailer-signature:$tsig\r\n\r\n";
   }
   $self->_done(1);
   return $body;
}

# true if the string holds only bytes, even if it is stored as UTF-8; it is
# passed by reference, so that big chunks are copied only when they are UTF-8
sub _is_bytes ($ref) {
   return !utf8::is_utf8($$ref) || utf8::downgrade(my $copy = $$ref, 1);
}

1;
