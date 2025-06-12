# -*-cperl-*-
#
# Crypt::RSA::Blind - Blind RSA signatures
# Copyright (c) Ashish Gulhati <crypt-rsab at hash.neo.email>
#
# $Id: lib/Crypt/RSA/Blind.pm v1.035 Wed Jun 11 13:34:13 EST 2025 $

use warnings;
use strict;

use v5.26;
use Feature::Compat::Class;
use feature qw(signatures);
no warnings qw(experimental::signatures);

class Crypt::RSA::Blind;

use vars qw( $VERSION );
our ( $VERSION ) = '$Revision: 1.035 $' =~ /\s+([\d\.]+)/;

use Carp;
use Carp::Assert;
use Crypt::FDH;
use Crypt::RSA;
use Crypt::RSA::DataFormat qw(bitsize i2osp os2ip octet_xor);
use Crypt::RSA::Primitives;
use Digest::SHA qw(sha384 sha384_hex);
use Math::Pari qw (Mod ceil component gcd lift);
use Crypt::Random qw(makerandom_itv makerandom);

field $hashsize :param :reader(get_hashsize) = 768;
field $initsize :param :reader(get_initsize) = 128;
field $blindsize :param :reader(get_blindsize) = 512;
field $hash_algorithm :reader(get_hash_algorithm) :param = 'SHA384';
field $mgf_hash_algorithm :reader(get_mgf) :param = 'SHA384';
field $slen :param :reader(get_slen) = 0;
field $oldapi :param :reader(get_oldapi) = 1;
field $rsa :reader(get_rsa) = Crypt::RSA->new;
field $rsap :reader(get_rsap) = Crypt::RSA::Primitives->new;
field $requests = {};
field $messages = {};

method set_hashsize ($value) { $hashsize = $value; }
method set_hash_algorithm ($value) { $hash_algorithm = $value; }
method set_mgf_hash_algorithm ($value) { $mgf_hash_algorithm = $value; }
method set_blindsize ($value) { $blindsize = $value; }
method set_initsize ($value) { $initsize = $value; }
method set_oldapi ($value) { $oldapi = $value; }
method set_slen ($value) { $slen = $value; }

method keygen (@args) {
  $self->get_rsa->keygen(@args);
}

method init () {
  makerandom( Size => $self->get_initsize, Strength => 1, Uniform => 1 );
}

# RSABSSA methods

method blind ($arg_ref) {
  my $n = $arg_ref->{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  my $encoded_msg = $self->EMSA_PSS_ENCODE($kbits, @$arg_ref{qw(Message sLen Salt)});
  my $m = os2ip($encoded_msg);

  croak("Invalid input") unless is_coprime($m, $n);

  my $r; my $r_inv;
  if ($arg_ref->{R_inv}) {  # for test vector verification
    $r_inv = $arg_ref->{R_inv};
    $r = mod_inverse($r_inv, $n);
  }
  else {
    while (!$r_inv) {
      $r = makerandom_itv( Size => 4096, Lower => 1, Upper => $n, Strength => 1, Uniform => 1 );
      # Check that blinding factor is invertible mod n
      $r_inv = mod_inverse($r, $n);
    }
  }
  $self->_request($arg_ref->{Init} => $r_inv, $arg_ref->{Message}) if $arg_ref->{Init};
  my $x = RSAVP1($arg_ref->{PublicKey}, $r);
  my $z = ($m * $x) % $n;
  my $blinded_msg = i2osp($z, $klen);
  my $inv = i2osp($r_inv, $klen);
  my $msglen = length($blinded_msg);
  croak("Unexpected message size (msglen: $msglen, klen: $klen") if $msglen != $klen;
  return ($blinded_msg, $inv);
}

method blind_sign ($arg_ref) {
  my $n = $arg_ref->{SecretKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  my $inputlen = length($arg_ref->{BlindedMessage});
  croak("Unexpected input size (inputlen: $inputlen, klen: $klen)") if $inputlen != $klen;
  my $m = os2ip($arg_ref->{BlindedMessage});
  croak("Invalid message length") if $m >= $n;
  my $s = RSASP1($arg_ref->{SecretKey}, $m);
  if (defined $arg_ref->{PublicKey}) {
    my $mdash = RSAVP1($arg_ref->{PublicKey}, $s);
    croak "Signing failure" unless $m == $mdash;
  }
  my $blind_sig = i2osp($s, $klen);
}

method finalize ($arg_ref) {
  my $n = $arg_ref->{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  my $z = os2ip($arg_ref->{BlindSig});
  my ($blinding, $message);
  unless ($arg_ref->{Blinding}) {
    my $saved = $self->_request($arg_ref->{Init});
    $blinding = $self->get_oldapi ? $saved->[0] : $saved;
    $message = $self->get_oldapi ? $saved->[1] : $arg_ref->{Message};
  }
  croak("Neither Blinding nor valid Init vector provided") unless my $r_inv = $arg_ref->{Blinding} ? os2ip($arg_ref->{Blinding}) : $blinding;
  my $s = ($z * $r_inv) % $n;
  my $sig = i2osp($s, $klen);
  $self->pss_verify( { PublicKey => $arg_ref->{PublicKey}, Signature => $sig, Message => $arg_ref->{Blinding} ? $arg_ref->{Message} : $message, sLen => $arg_ref->{sLen} } );
  return $sig;
}

method randomize ($msg) {
  my $random = makerandom(Size => 32 * 8, Strength => 1, Uniform => 1);
  $msg = i2osp($random, 32) . $msg;
}

method pss_verify ($arg_ref) {
  my $n = $arg_ref->{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  # Step 1
  my $siglen = length($arg_ref->{Signature});
  croak("Incorrect signature length (siglen: $siglen, klen: $klen") if $siglen != $klen;
  # Step 2a (OS2IP)
  my $signature_int = os2ip($arg_ref->{Signature});
  # Step 2b (RSAVP1)
  my $em_int = RSAVP1($arg_ref->{PublicKey}, $signature_int);
  # Step 2c (I2OSP)
  my $emlen = ceil(($kbits - 1)/8);
  my $em = i2osp($em_int, $emlen);
  my $hash = Digest::SHA->new($self->get_hash_algorithm);
  $hash->add($arg_ref->{Message});
  $self->EMSA_PSS_VERIFY($hash, $em, $kbits-1, sub { MGF1(@_) }, $arg_ref->{sLen});
  return 1
}

method EMSA_PSS_ENCODE ($kbits, $msg, $slen, $salt) {
  my $hash = Digest::SHA->new($self->get_hash_algorithm);
  $hash->add($msg);
  my $m_hash = $hash->hexdigest;
  my $hlen = ceil($hash->hashsize/8);

  my $embits = $kbits - 1;
  my $emlen = ceil($embits/8);
  assert($emlen >= $hlen + $slen + 2);

  my $lmask = 0;
  for (0..(8 * $emlen - $embits - 1)) {
    $lmask = $lmask >> 1 | 0x80;
  }

  unless ($salt) {
    $salt = '';
    $salt = uc(unpack ('H*',i2osp(makerandom(Size => $slen * 8, Strength => 1, Uniform => 1), $slen))) if $slen;
1  }

  my $m_prime = chr(0) x 8 . i2osp(Math::Pari::_hex_cvt('0x' . $m_hash . $salt), $hlen + $slen);
  $hash = Digest::SHA->new($self->get_hash_algorithm);
  $hash->add($m_prime);
  my $h = $hash->digest;
  my $ps = chr(0) x ($emlen - $slen - $hlen - 2);
  my $db = $ps . chr(0x01); $db .= i2osp(Math::Pari::_hex_cvt('0x' . $salt), $slen) if $slen;
  my $dbMask = MGF1($h, $emlen - $hlen - 1);
  my $masked_db = octet_xor($db, $dbMask);
  $masked_db = chr(os2ip(substr($masked_db, 0, 1)) & (~$lmask)) . substr($masked_db, 1);
  my $encoded_msg = $masked_db . $h . chr(0xBC);
}

method EMSA_PSS_VERIFY ($mhash, $em, $embits, $mgf, $slen) {
  my $hashlen = ceil($mhash->hashsize / 8);
  my $emlen = ceil($embits/8);
  my $lmask = 0;
  for (0..(8*$emlen-$embits-1)) {
    $lmask = $lmask >> 1 | 0x80
  }
  # Step 1 and 2 already done
  # Step 3
  croak("Incorrect signature at step 3") if ($emlen < $hashlen + $slen + 2);
  # Step 4
  croak("Incorrect signature at step 4") if ord(substr($em, -1)) != 0xBC;
  # Step 5
  my $masked_db = substr($em,0,$emlen-$hashlen-1);
  my $h = substr($em,$emlen-$hashlen-1,-1);
  # Step 6
  croak("Incorrect signature at step 6") if $lmask & ord(substr($em,0,1));
  # Step 7
  my $dbmask = &$mgf($h, $emlen-$hashlen-1);
  # Step 8
  my $db = octet_xor($masked_db, $dbmask);
  # Step 9
  $db = chr(ord(substr($db,0,1)) & ~$lmask) . substr($db,1);
  # Step 10
  croak("Incorrect signature at step 10") unless (substr($db, 0, $emlen-$hashlen-$slen-1) eq (chr(0) x ($emlen-$hashlen-$slen-2) . chr(1)));
  # Step 11
  my $salt = $slen > 0 ? substr($db,-$slen) : '';
  # Step 12
  my $m_prime = chr(0) x 8 . $mhash->digest . $salt;
  # Step 13
  my $hash = Digest::SHA->new($self->get_hash_algorithm);
  $hash->add($m_prime);
  my $hp = $hash->digest;
  # Step 14
  croak("Incorrect signature at step 14") if $h ne $hp;
}

# Old-style API methods

method request (%arg) {
  if ($self->get_oldapi) {
    my ($req, $blinding) = $self->blind( { PublicKey => $arg{Key}, sLen => $self->get_slen, %arg } );
    return os2ip($req);
  }
  $self->_req(%arg);
}

method sign (%arg) {
  my $klen = ceil(bitsize($arg{Key}->n)/8);
  $self->get_oldapi ? os2ip($self->blind_sign( { SecretKey => $arg{Key}, PublicKey => $arg{PublicKey}, BlindedMessage => i2osp($arg{Message}, $klen) } )) : $self->_sign(%arg);
}

method unblind (%arg) {
  my $klen = ceil(bitsize($arg{Key}->n)/8);
  $self->get_oldapi ? os2ip($self->finalize( { PublicKey => $arg{Key}, BlindSig => i2osp($arg{Signature}, $klen), sLen => $self->get_slen, %arg } )) : $self->_unblind(%arg);
}

method verify (%arg) {
  my $klen = ceil(bitsize($arg{Key}->n)/8);
  $self->get_oldapi ? $self->pss_verify( { PublicKey => $arg{Key}, %arg, Signature => i2osp($arg{Signature}, $klen), sLen => $self->get_slen } ) : $self->_verify(%arg);
}

# Deprecated methods

method _req (%arg) {
  carp('Call to deprecated method: request');
  my ($invertible, $blinding);
  while (!$invertible) {
    $blinding = makerandom_itv( Size => $self->get_blindsize, Upper => $arg{Key}->n-1, Strength => 1, Uniform => 0 );
    # Check that blinding is invertible mod n
    $invertible = gcd( $blinding, $arg{Key}->n );
    $invertible = 0 unless $invertible == 1;
  }
  $self->_request($arg{Init} => $blinding);

  my $be = $self->get_rsap->core_encrypt(Key => $arg{Key}, Plaintext => $blinding);
  my $fdh = Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->get_hashsize, Message => $arg{Message}));
  component((Mod($fdh,$arg{Key}->n)) * (Mod($be,$arg{Key}->n)), 2);
}

method _sign (@args) {
  carp('Call to deprecated method: sign');
  $self->get_rsap->core_sign(@args);
}

method _unblind (%arg) {
  carp('Call to deprecated method: unblind');
  my $blinding = $self->_request($arg{Init});
  component((Mod($arg{Signature},$arg{Key}->n)) / (Mod($blinding,$arg{Key}->n)), 2);
}

method _verify (%arg) {
  carp('Call to deprecated method: verify');
  my $pt = $self->get_rsap->core_verify(Key => $arg{Key}, Signature => $arg{Signature});
  $pt == Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->get_hashsize, Message => $arg{Message}));
}

# Helper methods and functions

method errstr (@args) {
  $self->rsa->errstr(@args);
}

method _request ($init, $blinding=undef, $message=undef) {       # Save / retrieve blinding by init vector
  my $ret;
  if ($blinding) {                                               # Associate blinding with init vector
    $requests->{$init} = $blinding;
    $messages->{$init} = $message if $self->get_oldapi;
  }
  else {                                                         # Retrieve blinding associated with init vector
    $ret = $self->get_oldapi ?
      [ $requests->{$init}, $messages->{$init} ] :
      $requests->{$init};
    delete $requests->{$init};
    delete $messages->{$init} if $self->get_oldapi;
  }
  return $ret;
}

sub RSAVP1 ($pubkey, $s) {
  my $e = $pubkey->e;
  my $n = $pubkey->n;
  my $scopy = $s; my $ncopy = $n;
  croak "Signature representative out of range" unless $scopy < $ncopy and $scopy > 0;
  my $m = mod_exp($s, $e, $n);
}

sub RSASP1 ($seckey, $m) {
  my $d = $seckey->d;
  my $n = $seckey->n;
  my $mcopy = $m; my $ncopy = $n;
  croak "Message representative out of range" unless $mcopy < $ncopy and $mcopy > 0;
  my $s = mod_exp($m, $d, $n);
}

sub MGF1 ($seed, $masklen) {
  my $hlen = 48;
  my $T = '';
  for (0..ceil($masklen/$hlen)-1) {
    my $c = i2osp($_, 4);
    $T = $T . sha384($seed . $c);
  }
  assert(length($T) >= $masklen);
  unpack "a$masklen", $T;
}

sub is_coprime {
  gcd(@_) == 1;
}

sub mod_inverse {
  my($a, $n) = @_;
  my $m = Mod(1, $n);
  lift($m / $a);
}

sub mod_exp {
  my($a, $exp, $n) = @_;
  my $m = Mod($a, $n);
  lift($m ** $exp);
}

package Crypt::RSA::Blind::PubKey {
  use Compress::Zlib;
  sub from_hex ($pubkey) {
    Crypt::RSA::Key::Public->new->deserialize(String => [ uncompress(pack('H*',$pubkey)) ]);
  }
}

package Crypt::RSA::Blind::SecKey {
  use Compress::Zlib;
  sub from_hex ($seckey) {
    Crypt::RSA::Key::Private->new->deserialize(String => [ uncompress(pack('H*',$seckey)) ]);
  }
}

1;

__END__

=head1 NAME

Crypt::RSA::Blind - Blind RSA signatures

=head1 VERSION

 $Revision: 1.035 $
 $Date: Wed Jun 11 13:34:13 EST 2025 $

=cut

=head1 SYNOPSIS

    use Crypt::RSA::Blind;
    use Try::Tiny;

    my $rsab = new Crypt::RSA::Blind;

    my ($pubkey, $seckey) = $rsab->keygen(Size => 4096);

    my $msg = "Hello, world!";

    # RSABSSA-PSS methods (RFC 9474)

    my $slen = 48; # Salt length (in bytes). 0 for no salt.

    my ($blinded_msg, $blinding) = $rsab->blind ( { PublicKey => $pubkey,
                                                    Message => $msg,
                                                    sLen => $slen } );

    my $blind_sig = $rsab->blind_sign( { SecretKey => $seckey,
                                         PublicKey => $pubkey,
                                         BlindedMessage => $blinded_msg } );

    my $sig = $rsab->finalize( { PublicKey => $pubkey,
                                 BlindSig => $blind_sig,
                                 Blinding => $blinding,
                                 Message => $msg,
                                 sLen => $slen } );

    print "OK\n" if try { $rsab->pss_verify( { PublicKey => $pubkey,
                                               Signature => $sig,
                                               Message => $msg,
                                               sLen => $slen } ) };

    # Use old API methods as wrappers for RSABSSA-PSS methods

    $rsab->set_oldapi(1);     # Enable old API wrappers (default)

    # Alternately, use old API methods as originally implemented

    $rsab->set_oldapi(0);     # Disable old API wrappers (deprecated)

    # Old interface

    my $init = $rsab->init;

    my $req = $rsab->request( Key => $pubkey,
                              Init => $init,
                              Message => $msg );

    my $blindsig = $rsab->sign( Key => $seckey,
                                PublicKey => $pubkey,
                                Message => $req );

    my $sig = $rsab->unblind( Key => $pubkey,
                              Init => $init,
                              Signature => $blindsig );

    print "OK\n" if $rsab->verify( Key => $pubkey,
                                   Message => $msg,
                                   Signature => $sig );

=head1 METHODS

=head2 new

Creates and returns a new C<Crypt::RSA::Blind> object.

=head2 keygen

Generates and returns an RSA key-pair of specified bitsize. This is a
synonym for C<Crypt::RSA::Key::generate>. Arguments and return values
are described in the L<Crypt::RSA::Key> manpage.

=head2 init

Generates and returns an initialization vector.

The RSA blind signature protocol doesn't require the use of
initialization vectors. However, this module can use them to keep
track of the blinding factor for different signing requests, so it is
convenient to use initialization vectors when creating multiple
interlaved signing requests.

When using initialization vectors, the vector should be passed as the
C<Init> named argument to the C<blind> and C<finalize> methods
(in the old deprecated interface, to the C<request> and C<unblind>
methods).

Alternately, you can keep track of the blinding factor for each
request in your own code. In this case, you can supply the blinding
factor as the C<Blinding> named argument to the C<finalize> method,
instead of providing an initialization vector as the C<Init> argument
to C<blind> and C<finalize>.

Initialization vectors are not persistent across different invocations
of a script, so if you need to call C<blind> and C<finalize> in
different processes, you will need to record and persist the blinding
factor yourself.

=head2 blind

Generate a blinding factor and a blinded message for signing.

Returns a list of two binary strings. The first is a the blinded
message for signing, the second is the blinding factor used. Raises an
exception on error.

Expects a hashref containing named arguments. The following arguments
are required:

=over

B<PublicKey> - The public key of the signer

B<Message> - The message to be blind signed

B<sLen> - The length (in bytes) of the salt to be used in the RSABSSA-PSS
protocol. This can be 0 for no salt.

=back

The following optional arguments can be provided:

=over

B<Init> - An initialization vector from init()

B<R_inv> - The r_inv value as an integer, for test vector verification.

B<Salt> - A salt as a hex string without a leading '0x', for test vector
verification.

=back

=head2 blind_sign

Generate a blind signature.

Returns the blind signature as a binary string. Raises an exception on
error.

Expects a hashref containing named arguments. The following arguments
are required:

=over

B<SecretKey> - The private key of the signer

B<BlindedMessage> - The blinded message from blind()

=back

The following optional arguments can be provided:

=over

B<PublicKey> - The public key of the signer. If this is provided, the
blind signature will be verified as an implementation safeguard. This
is required by RFC9474.

=back

=head2 finalize

Unblind a blind signature and generate an RSASSA-PSS compatible
signature.

Returns the signature as a binary string. Raises an exception on
error.

Expects a hashref containing named arguments. The following arguments
are required:

=over

B<PublicKey> - The public key of the signer

B<BlindSig> - The blind signature from blind_sign()

B<Message> - The message that was provided to blind()

B<sLen> - The lengh in bytes of the salt. 0 for no salt.

=back

In addition, one of the following arguments is required:

=over

B<Init> - The initialization vector that was provided to blind()

B<Blinding> - The blinding factor that was returned by blind()

=back

=head2 pss_verify

Verify an RSABSSA-PSS signature.

Returns a true value if the signature verifies successfully. Raises an
exception on error.

Expects a hashref containing named arguments. The following named
arguments are required:

=over

B<PublicKey> - The public key of the signer

B<Signature> - The blind signature

B<Message> - The message that was signed

B<sLen> - The lengh in bytes of the salt. 0 for no salt.

=back

=head2 randomize

Takes a single required argument, the message to be signed (as a
binary string), and returns a prepared message with a random prefix
(also as a binary string).

=head2 errstr

Returns the error message from the last failed method call. See
L</ERROR HANDLING> below for more details.

=head1 OLD API MODES

The methods under L</OLD API METHODS> below are the original interface for
this module. They continue to be available in two modes for backwards
compatibility.

The first, recommended, and default mode for these methods is
"compatibility mode", which can be enabled with:

    $rsab->set_oldapi(1);     # Enable old API wrappers

In this mode, the old methods are wrappers around the RSABSSA-PSS
methods described above. Code written with the old methods should work
in this mode, and will use the updated implementation.

In the second mode the old methods invoke their original
implementation. This mode can be enabled with:

    $rsab->set_oldapi(0);     # Disable old API wrappers

This mode is deprecated as the old implementation predates RFC 9474
and isn't compliant with it.

While these original methods continue to be available, versions 1.020
and higher of this module use different accessor names than previous
versions. This change is incompatible with code that uses the old
accessors. See L</ACCESSORS> below.

=head1 OLD API METHODS

=head2 request

Generates and returns a blind-signing request. The following named
arguments are required:

=over

B<Init> - The initialization vector from init()

B<Key> - The public key of the signer

B<Message> - The message to be blind signed

=back

=head2 sign

Generates and returns a blind signature. The following named
arguments are required:

=over

B<Key> - The private key of the signer

B<Message> - The blind-signing request

=back

The following optional arguments can be provided:

=over

B<PublicKey> - The public key of the signer. If this is provided, the
blind signature will be verified as an implementation safeguard. This
is required by RFC9474.

=back

=head2 unblind

Unblinds a blind signature and returns a verifiable signature. The
following named arguments are required:

=over

B<Init> - The initialization vector from init()

B<Key> - The public key of the signer

B<Signature> - The blind signature

=back

=head2 verify

Verify a signature. The following named arguments are required:

=over

B<Key> - The public key of the signer

B<Signature> - The blind signature

B<Message> - The message that was signed

=back

=head1 ACCESSORS

Accessors can be used to query or set the value of an object
property. Readers are prefixed with "get_". Writers are prefixed with
"set_" and take a single argument, to set the property to a specific
value.

Version 1.012 and older of this module used different accessor names
and didn't use the get_ and set_ prefixes. Code that uses the old
accessors will need to be updated to use the new ones.

=head2 get_hash_algorithm / set_hash_algorithm

The name of the hashing algorithm to be used. Only SHA variants are
supported. The default is 'SHA384'.

=head2 get_mgf_hash_algorithm / set_mgf_hash_algorithm

The name of the hashing algorithm to be used in the MGF1
function. Only SHA variants are supported. The default is 'SHA384'.

=head2 get_initsize / set_initsize

The bitsize of the init vector. Default is 128.

=head2 get_hashsize / set_hashsize

The bitsize of the full-domain hash that will be generated from the
message to be blind-signed. Default is 768. This property is only
relevant to the old deprecated implementation.

=head2 get_blindsize / set_blindsize

The bitsize of the blinding factor. Default is 512. This property is
only relevant to the old deprecated implementation.

=head2 get_oldapi / set_oldapi

Enable / disable compatibility mode for the original
C<Crypt::RSA::Blind> API to wrap the RSABSSA-PSS
methods. C<set_oldapi(1)> enables wrapping RSABSSA-PSS in the old API
methods. C<set_oldapi(0)> disables wrapping and uses the original
implementation for the original methods. This mode is deprecated.

=head1 ERROR HANDLING

C<Crypt::RSA::Blind> relies on L<Crypt::RSA>, which uses an error handling
method implemented in L<Crypt::RSA::Errorhandler>. When a method fails
it returns undef and saves the error message. This error message is
available to the caller through the C<errstr> method. For more details
see the L<Crypt::RSA::Errorhandler> manpage.

Other than C<keygen>, only the "old API" methods of C<Crypt::RSA::Blind>
report errors this way, when operating with their original
implementation. See L</OLD API MODES> above.

The C<blind>, C<blind_sign>, C<finalize> and C<pss_verify> methods do not
use the above error reporting method. They raise an exception on
error. As do the "old API" methods when operating in compatibility
mode (see L</OLD API MODES> above).

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-rsab at hash.neo.email> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-rsa-blind at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-RSA-Blind>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 4.0.

Please see the LICENSE file included with this package, or visit
L<http://www.opensoftware.ca/oal40.txt>, for the full license terms,
and ensure that the license grant applies to you before using or
modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
