package AWS::Signature::V4::Checksum;
use v5.24;
use Moo;
use Compress::Raw::Zlib ();
use Digest::SHA ();
use MIME::Base64 qw< encode_base64 >;
use AWS::Signature::V4::Error qw< fail >;
use experimental qw< signatures >;

use constant {
   # name => size of the raw checksum, in bytes
   SIZE_FOR => +{ crc32 => 4, crc32c => 4, sha1 => 20, sha256 => 32 },

   # crc32c comes from String::CRC32C when it is installed (it is much
   # faster), otherwise from the slicing-by-4 code below: $T0[$b] is the
   # effect of byte $b on the register, $T1 to $T3 that of the same byte
   # followed by 1 to 3 zeros
   CRC32C_XS => eval { require String::CRC32C; \&String::CRC32C::crc32c },
};

use namespace::clean;

has algorithm => (is => 'ro', required => 1);

# running state: the CRCs keep a number, the SHA ones a Digest::SHA object
has _crc => (is => 'rw', lazy => 1, builder => 1);
has _sha => (is => 'lazy');

# the algorithm is given as the only, positional, argument: new('crc32')
around BUILDARGS => sub ($orig, $class, @args) {
   return {algorithm => $args[0]} if @args == 1 && !ref $args[0];
   return $class->$orig(@args);
};

sub _build__crc ($self) { $self->algorithm eq 'crc32c' ? 0xFFFFFFFF : 0 }
sub _build__sha ($self) { Digest::SHA->new($self->algorithm eq 'sha1' ? 1 : 256) }

sub encoded_size ($class, $algo) { 4 * int((SIZE_FOR->{$algo} + 2) / 3) }

sub add ($self, $ref) {    # $ref: reference to a byte string
   fail 400, 'checksum data must be a reference to a byte string'
      unless ref $ref eq 'SCALAR' && defined $$ref;
   utf8::is_utf8($$ref) && !utf8::downgrade(my $copy = $$ref, 1)
      and fail 400, 'checksum data must be a byte string: encode characters first';
   my $algo = $self->algorithm;
   if ($algo eq 'crc32') {
      $self->_crc(Compress::Raw::Zlib::crc32($$ref, $self->_crc));
   }
   elsif ($algo eq 'crc32c') {
      $self->_crc(_crc32c($self->_crc, $ref));
   }
   else { $self->_sha->add($$ref) }
   return $self;
}

# register after the data; String::CRC32C wants and gives it inverted
sub _crc32c ($crc, $ref) {
   return CRC32C_XS->($$ref, $crc ^ 0xFFFFFFFF) ^ 0xFFFFFFFF if CRC32C_XS;

   state $T0 = [
      map {
         my $c = $_;
         $c = ($c & 1) ? (($c >> 1) ^ 0x82F63B78) : ($c >> 1) for 1 .. 8;
         $c;
      } 0 .. 255
   ];
   state $T1 = [ map { $T0->[$T0->[$_] & 0xFF] ^ ($T0->[$_] >> 8) } 0 .. 255 ];
   state $T2 = [ map { $T0->[$T1->[$_] & 0xFF] ^ ($T1->[$_] >> 8) } 0 .. 255 ];
   state $T3 = [ map { $T0->[$T2->[$_] & 0xFF] ^ ($T2->[$_] >> 8) } 0 .. 255 ];


   my $words = length($$ref) & ~3;
   for (my $offset = 0; $offset < $words; $offset += 65536) {    # bounded lists
      my $size = $words - $offset < 65536 ? $words - $offset : 65536;
      for my $word (unpack 'V*', substr $$ref, $offset, $size) {
         my $c = $crc ^ $word;
         $crc = $T3->[$c & 0xFF]
                ^ $T2->[($c >> 8) & 0xFF]
                ^ $T1->[($c >> 16) & 0xFF]
                ^ $T0->[$c >> 24];
      }
   }
   $crc = $T0->[($crc ^ $_) & 0xFF] ^ ($crc >> 8) for unpack 'C*', substr $$ref, $words;
   return $crc;
}

sub base64 ($self) {
   my $algo = $self->algorithm;
   my $raw =
        $algo eq 'crc32'  ? pack('N', $self->_crc)
      : $algo eq 'crc32c' ? pack('N', $self->_crc ^ 0xFFFFFFFF)
      :                     $self->_sha->digest;
   return encode_base64($raw, '');
}

sub is_supported_algorithm ($co, $name) { exists(SIZE_FOR->{$name}) }

sub supported_algorithms { sort { $a cmp $b } keys(SIZE_FOR->%*) }

1;
