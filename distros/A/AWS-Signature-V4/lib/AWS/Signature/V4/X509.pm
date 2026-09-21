package AWS::Signature::V4::X509;
use v5.24;
use experimental qw< signatures >;
use Moo;
use MIME::Base64 qw< encode_base64 decode_base64 >;
use Math::BigInt;

use AWS::Signature::V4::Error qw< fail shown >;

# a plain string or an arrayref of plain strings => arrayref
sub _items ($value, $name) {
   $value = [$value] unless ref $value;
   ref $value eq 'ARRAY'
      or fail 400, "x509/$name must be a string or an array reference";
   for my $item ($value->@*) {
      fail 400, "x509/$name must hold strings" if !defined $item || ref $item;
   }
   return $value;
}

sub _b64 ($der) { encode_base64($der, '') }

# ---- X.509 helpers (no external dependencies) ------------------------------

sub _slurp ($file) {
   open my $fh, '<:raw', $file or fail 400, 'open(' . shown($file) . "): $!";
   local $/;
   my $data = <$fh>;
   close $fh;
   return $data;
}

sub _to_ders ($cert) {    # PEM bundles hold many certificates
   return _check_der($cert) unless $cert =~ m{-----BEGIN};
   my @ders = map { decode_base64($_) }
      $cert =~ m{-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----}sg;
   @ders or fail 400, 'no CERTIFICATE block in PEM';
   return map { _check_der($_) } @ders;
}

sub _to_der ($cert) {
   return _check_der($cert) unless $cert =~ m{-----BEGIN};
   $cert =~ m{-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----}s
      or fail 400, 'no CERTIFICATE block in PEM';
   return _check_der(decode_base64($1));
}

# a certificate is a DER SEQUENCE that fits exactly in the data
sub _check_der ($der) {
   my ($tag, undef, $end) = _tlv($der, 0);
   fail 400, 'not a DER-encoded certificate'
      unless $tag == 0x30 && $end == length $der;
   return $der;
}

# read one DER TLV at $off => (tag, content_start, content_end)
sub _tlv ($der, $off) {
   my $max = length $der;
   $off + 2 <= $max or fail 400, 'truncated certificate';
   my $tag = ord substr $der, $off++, 1;
   my $len = ord substr $der, $off++, 1;
   if ($len & 0x80) {    # long form, DER wants it minimal and definite
      my $n = $len & 0x7F;
      fail 400, 'not a DER-encoded certificate' if $n == 0 || $n > 4;
      $off + $n <= $max or fail 400, 'truncated certificate';
      $len = 0;
      $len = ($len << 8) | ord substr($der, $off++, 1) for 1 .. $n;
      fail 400, 'not a DER-encoded certificate'
         if $len < 0x80 || $len < 1 << 8 * ($n - 1);
   }
   $off + $len <= $max or fail 400, 'truncated certificate';
   return ($tag, $off, $off + $len);
}

# Certificate ::= SEQ { tbs SEQ { [0] version?, INTEGER serial, ... }, ... }
sub _certificate_serial ($der) {
   my (undef, $cs) = _tlv($der, 0);
   my (undef, $ts) = _tlv($der, $cs);
   my ($tag, $s, $e) = _tlv($der, $ts);
   ($tag, $s, $e) = _tlv($der, $e) if $tag == 0xA0;    # skip explicit version
   fail 400, 'cannot find certificate serial number' unless $tag == 0x02;
   return Math::BigInt->from_hex(unpack 'H*', substr $der, $s, $e - $s)
      ->bstr;   # DER integers here are positive; leading 0x00 is harmless
}

# The error of CryptX, without the location and the backtrace that Carp adds
# when verbose (the arguments in it may hold the password), escaped as caller
# input because it can hold the file name.
sub _clean_error ($e) {
   $e =~ s{\n\t.*}{}s;    # the backtrace lines start with a tab
   $e =~ s{\s+at \S+ line \d+\.?\s*\z}{};
   return shown($e =~ s{\A\s+|\s+\z}{}gr);
}

# $key is a file name or a scalar reference to the PEM text
sub _cryptx_signer ($algo, $key, $password = undef) {
   my $class = $algo eq 'RSA' ? 'Crypt::PK::RSA' : 'Crypt::PK::ECC';
   eval "require $class; 1" or fail 500, "cannot load $class";
   my @args = ($key, defined $password ? ($password) : ());
   my $pk = eval {
      # no backtrace, e.g. from -MCarp=verbose or Carp::Always, with the password
      local $Carp::Verbose = 0;
      local $Carp::MaxArgNums = -1;
      local $SIG{__DIE__};
      $class->new(@args);
   } // fail 400, "cannot load the private key: " . _clean_error($@);
   fail 400, 'the key is not a private key' unless $pk->is_private;
   return $algo eq 'RSA'
      ? sub ($bytes) { $pk->sign_message($bytes, 'SHA256', 'v1.5') }
      : sub ($bytes) { $pk->sign_message($bytes, 'SHA256') };
}

use namespace::clean;

# The certificate-based variant, as used by IAM Roles Anywhere. The options
# are the ones of the "x509" option of AWS::Signature::V4:
#   certificate / certificate_file: PEM or DER text, or path of a file with it;
#                only the first certificate of a PEM bundle is used
#   chain / chain_files: optional arrayref of PEM/DER intermediate certificates,
#                or of paths of files with them; a PEM item can be a bundle.
#                chain can also be a plain string: a PEM-encoded bundle, and
#                chain_files a plain string: the path of one file
#   key_type:    'RSA' or 'ECDSA'
#   serial:      the serial number of the certificate, if it cannot be found
#   signer:      sub ($bytes_to_sign) -> raw signature bytes (DER for ECDSA,
#                PKCS#1 v1.5 for RSA), computed with SHA-256; or, alternatively,
#   private_key_file / private_key: PEM or DER key (path or content, the
#                content wins), signed with CryptX; private_key_password if it
#                is encrypted
has [qw<
   key_type certificate certificate_file chain chain_files serial signer
   private_key_file
>] => (is => 'ro');

# the key text and its password are secrets, only needed to load the key:
# no public accessor, and they are dropped as soon as the key is loaded
has $_ => (is => 'ro', reader => "_$_", clearer => "_clear_$_")
   for qw< private_key private_key_password >;

# Derived from the options above. Lazy, so that each builder can use the
# others without depending on the order in which the constructor sets things
# up; BUILD forces them all, so that a bad certificate, chain or key is
# reported by new() and not by the first signature.
#
# **NOTE**: to add one, add its name here and write its builder.
my @DERIVED = qw< algorithm credential_id _chain _der _signer _type >;
has $_ => (is => 'lazy', init_arg => undef) for @DERIVED;

sub BUILD ($self, $args) {
   my %known = map { $_ => 1 } qw<
      key_type certificate certificate_file chain chain_files serial signer
      private_key_file private_key private_key_password
   >;
   if (my ($name) = sort(grep { !$known{$_} } keys $args->%*)) {
      fail 400, 'unknown option "' . shown($name) . '" in x509';
   }
   for my $name (@DERIVED) {    # not "for (...)": builders may use $_
      $self->$name;
   }

   # we don't need private key material past this point, so we get rid
   # of it immediately. Of course it may still linger in memory depending
   # on garbage collection.
   $self->_clear_private_key;
   $self->_clear_private_key_password;
   return;
}

sub _build__type ($self) {
   my $type = uc($self->key_type // fail 400, 'missing x509/key_type');
   fail 400, 'x509/key_type must be RSA or ECDSA, got ' . shown($type)
      unless $type eq 'RSA' || $type eq 'ECDSA';
   return $type;
}

sub _build_algorithm ($self) { 'AWS4-X509-' . $self->_type . '-SHA256' }

sub _build__der ($self) {
   my $cert = $self->certificate;
   if (!defined $cert && defined $self->certificate_file) {
      $cert = _slurp($self->certificate_file);
   }
   defined $cert or fail 400, 'x509 needs "certificate" or "certificate_file"';
   return _to_der($cert);
}

sub _build__chain ($self) {
   my $chain = $self->chain;
   if (!defined $chain && defined $self->chain_files) {
      my $files = _items($self->chain_files, 'chain_files');    # a single path or an arrayref
      $chain = [map { _slurp($_) } $files->@*];
   }
   if (defined $chain && !ref $chain) {    # a plain string is a PEM bundle
      $chain =~ m{-----BEGIN CERTIFICATE-----}
         or fail 400, 'x509/chain as a string must be PEM-encoded';
   }
   return [map { _to_ders($_) } _items($chain // [], 'chain')->@*];
}

sub _build_credential_id ($self) {
   return $self->serial // _certificate_serial($self->_der);
}

sub _build__signer ($self) {
   my $type = $self->_type;
   my $signer = $self->signer;
   fail 400, '"signer" must be a code reference'
      if defined $signer && ref $signer ne 'CODE';
   if (!$signer && defined $self->_private_key) {    # the content wins, as for certificate
      my $key = $self->_private_key;    # CryptX wants a reference for a PEM/DER text
      $signer = _cryptx_signer($type, \$key, $self->_private_key_password);
   }
   elsif (!$signer && defined $self->private_key_file) {
      $signer = _cryptx_signer($type, $self->private_key_file, $self->_private_key_password);
   }
   return $signer
      // fail 400, 'x509 needs one of "signer", "private_key_file", "private_key"';
}

# ---- what AWS::Signature::V4 wants from a variant --------------------------

# hex signature of the string to sign; the scope is not used here
sub signature ($self, $scope, $string_to_sign) {
   my $sig = $self->_signer->($string_to_sign);
   fail 400, 'the x509 signer returned no signature'
      unless defined $sig && !ref $sig && length $sig;
   utf8::downgrade($sig, 1)
      or fail 400, 'the x509 signer returned a string with wide characters';
   return unpack 'H*', $sig;
}

# what goes with the request besides the signature, as (name => value) pairs
sub extra_fields ($self) {
   my $chain = $self->_chain;
   return (
      'X-Amz-X509' => _b64($self->_der),
      ($chain->@* ? ('X-Amz-X509-Chain' => join ',', map { _b64($_) } $chain->@*) : ()),
   );
}

# No derived key, so no signed chunks. This is stated twice, on purpose:
# AWS::Signature::V4 asks can_sign_chunks() up front, to refuse the request
# before doing anything else, and signing_key() is what fails if somebody
# asks for the key anyway. If this ever changes, change BOTH, and the
# corresponding tests in t/variants.t.
sub can_sign_chunks ($self) { 0 }
sub signing_key ($self, $scope) {
   fail 400, 'signed streaming needs the credentials variant, not x509';
}

1;
