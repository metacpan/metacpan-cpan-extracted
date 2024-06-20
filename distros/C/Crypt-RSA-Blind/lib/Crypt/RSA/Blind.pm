# -*-cperl-*-
#
# Crypt::RSA::Blind - Blind RSA signatures
# Copyright (c) Ashish Gulhati <crypt-rsab at hash.neo.email>
#
# $Id: lib/Crypt/RSA/Blind.pm v1.012 Sun Jun 16 18:22:22 EST 2024 $

package Crypt::RSA::Blind;

use warnings;
use strict;

use Carp;
use Carp::Assert;
use Crypt::FDH;
use Crypt::Random qw(makerandom_itv makerandom);
use Crypt::RSA;
use Crypt::RSA::DataFormat qw(bitsize i2osp os2ip octet_xor);
use Crypt::RSA::Primitives;
use Digest::SHA qw(sha384 sha384_hex);
use Math::Pari qw (Mod component gcd ceil);
use Attribute::Deprecated;

use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.012 $' =~ /\s+([\d\.]+)/;

sub new {
  bless { HASHSIZE  => 768,
	  INITSIZE  => 128,
	  BLINDSIZE => 512,
	  HASHALG   => 'SHA384',
	  MGFHALG   => 'SHA384',
	  _RSA      => new Crypt::RSA,
	  _RSAP     => new Crypt::RSA::Primitives}, shift;
}

sub keygen {
  my $self = shift;
  $self->_rsa->keygen(@_);
}

sub init {
  my $self = shift;
  makerandom( Size => $self->initsize, Strength => 0, Uniform => 1 );
}

# RSABSSA methods

sub ssa_blind {
  my ($self, %arg) = @_;
  my $n = $arg{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  my $encoded_msg = $self->EMSA_PSS_ENCODE($kbits, $arg{Message}, $arg{sLen}, $arg{Salt});
  my $m = os2ip($encoded_msg);

  croak "Invalid input" unless is_coprime($m, $n);

  my $r; my $r_inv;
  if ($arg{R_inv}) {  # for test vector verification
    $r_inv = $arg{R_inv};
    $r = Crypt::RSA::Primitives::mod_inverse($r_inv, $n);
  }
  else {
    while (!$r_inv) {
      $r = makerandom_itv( Size => 4096, Lower => 1, Upper => $n, Strength => 1, Uniform => 1 );
      # Check that blinding factor is invertible mod n
      $r_inv = Crypt::RSA::Primitives::mod_inverse($r, $n);
    }
  }
  $self->_request($arg{Init} => $r_inv) if $arg{Init};
  my $x = RSAVP1($arg{PublicKey}, $r);
  my $z = ($m * $x) % $n;
  my $blinded_msg = i2osp($z, $klen);
  my $inv = i2osp($r_inv, $klen);
  return ($blinded_msg, $inv);
}

sub ssa_blind_sign {
  my ($self, %arg) = @_;
  my $n = $arg{SecretKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  croak "Unexpected input size" if length($arg{BlindedMessage}) != $klen;
  my $d = $arg{SecretKey}->d;
  my $m = os2ip($arg{BlindedMessage});
  croak "Invalid message length" if $m >= $n;
  my $s = Crypt::RSA::Primitives::mod_exp($m, $d, $n);
  my $blind_sig = i2osp($s, $klen);
}

sub ssa_finalize {
  my ($self, %arg) = @_;
  my $n = $arg{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  my $z = os2ip($arg{BlindSig});
  croak "Neither Blinding nor valid Init vector provided" unless my $r_inv = $arg{Blinding} ? os2ip($arg{Blinding}) : $self->_request($arg{Init});
  my $s = ($z * $r_inv) % $n;
  my $sig = i2osp($s, $klen);
  $self->pss_verify(PublicKey => $arg{PublicKey}, Signature => $sig, Message => $arg{Message}, sLen => $arg{sLen});
  return $sig;
}

sub ssa_randomize {
  my ($self, $msg) = @_;
  $msg = i2osp(makerandom(Size => 32 * 8, Strength => 0, Uniform => 1)) . $msg;
}

sub pss_verify {
  my ($self, %arg) = @_;
  my $n = $arg{PublicKey}->n;
  my $kbits = bitsize($n);
  my $klen = ceil($kbits/8);
  # Step 1
  croak "Incorrect signature" if length($arg{Signature}) != $klen;
  # Step 2a (OS2IP)
  my $signature_int = os2ip($arg{Signature});
  # Step 2b (RSAVP1)
  my $em_int = RSAVP1($arg{PublicKey}, $signature_int);
  # Step 2c (I2OSP)
  my $emlen = ceil(($kbits - 1)/8);
  my $em = i2osp($em_int, $emlen);
  my $hash = Digest::SHA->new($self->hashalg);
  $hash->add($arg{Message});
  $self->EMSA_PSS_VERIFY($hash, $em, $kbits-1, sub { MGF1(@_) }, $arg{sLen});
  return 1
}

sub EMSA_PSS_ENCODE {
  my ($self, $kbits, $msg, $slen, $salt) = @_;
  my $hash = Digest::SHA->new($self->hashalg);
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
    $salt = uc(unpack ('H*',i2osp(makerandom(Size => $slen * 8, Strength => 0, Uniform => 1)))) if $slen;
  }

  my $m_prime = chr(0) x 8 . i2osp(Math::Pari::_hex_cvt('0x' . $m_hash . $salt));
  $hash = Digest::SHA->new($self->hashalg);
  $hash->add($m_prime);
  my $h = $hash->digest;
  my $ps = chr(0) x ($emlen - $slen - $hlen - 2);
  my $db = $ps . chr(0x01); $db .= i2osp(Math::Pari::_hex_cvt('0x' . $salt)) if $slen;
  my $dbMask = MGF1($h, $emlen - $hlen - 1);
  my $masked_db = octet_xor($db, $dbMask);
  $masked_db = chr(os2ip(substr($masked_db, 0, 1)) & (~$lmask)) . substr($masked_db, 1);
  my $encoded_msg = $masked_db . $h . chr(0xBC);
}

sub EMSA_PSS_VERIFY {
  my ($self, $mhash, $em, $embits, $mgf, $slen) = @_;
  my $hashlen = ceil ($mhash->hashsize / 8);
  my $emlen = ceil($embits/8);
  my $lmask = 0;
  for (0..(8*$emlen-$embits-1)) {
    $lmask = $lmask >> 1 | 0x80
  }
  # Step 1 and 2 already done
  # Step 3
  croak "Incorrect signature" if ($emlen < $hashlen + $slen + 2);
  # Step 4
  croak "Incorrect signature" if ord(substr($em, -1)) != 0xBC;
  # Step 5
  my $masked_db = substr($em,0,$emlen-$hashlen-1);
  my $h = substr($em,$emlen-$hashlen-1,-1);
  # Step 6
  croak "Incorrect signature" if $lmask & ord(substr($em,0,1));
  # Step 7
  my $dbmask = &$mgf($h, $emlen-$hashlen-1);
  # Step 8
  my $db = octet_xor($masked_db, $dbmask);
  # Step 9
  $db = chr(ord(substr($db,0,1)) & ~$lmask) . substr($db,1);
  # Step 10
  croak "Incorrect signature" unless (substr($db, 0, $emlen-$hashlen-$slen-1) eq (chr(0) x ($emlen-$hashlen-$slen-2) . chr(1)));
  # Step 11
  my $salt = $slen > 0 ? substr($db,-$slen) : '';
  # Step 12
  my $m_prime = chr(0) x 8 . $mhash->digest . $salt;
  # Step 13
  my $hash = Digest::SHA->new($self->hashalg);
  $hash->add($m_prime);
  my $hp = $hash->digest;
  # Step 14
  croak "Incorrect signature" if $h ne $hp;
}

# Deprecated methods

sub request : Deprecated {
  my $self = shift;
  my %arg = @_;
  my ($invertible, $blinding);
  while (!$invertible) {
    $blinding = makerandom_itv( Size => $self->blindsize, Upper => $arg{Key}->n-1, Strength => 1, Uniform => 1 );
    # Check that blinding is invertible mod n
    $invertible = Math::Pari::gcd($blinding, $arg{Key}->n);
    $invertible = 0 unless $invertible == 1;
  }
  $self->_request($arg{Init} => $blinding);

  my $be = $self->_rsap->core_encrypt(Key => $arg{Key}, Plaintext => $blinding);
  my $fdh = Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->hashsize, Message => $arg{Message}));
  component((Mod($fdh,$arg{Key}->n)) * (Mod($be,$arg{Key}->n)), 2);
}

sub sign : Deprecated {
  my $self = shift;
  $self->_rsap->core_sign(@_);
}

sub unblind : Deprecated {
  my $self = shift;
  my %arg = @_;
  my $blinding = $self->_request($arg{Init});
  component((Mod($arg{Signature},$arg{Key}->n)) / (Mod($blinding,$arg{Key}->n)), 2);
}

sub verify : Deprecated {
  my $self = shift;
  my %arg = @_;
  my $pt = $self->_rsap->core_verify(Key => $arg{Key}, Signature => $arg{Signature});
  $pt == Math::Pari::_hex_cvt ('0x'.Crypt::FDH::hash(Size => $self->hashsize, Message => $arg{Message}));
}

# Helper methods and functions

sub errstr {
  my $self = shift;
  $self->_rsa->errstr(@_);
}

sub _request {
  my $self = shift;
  my $init = $_[0]; my $ret;
  if ($_[1]) {
    $self->{Requests}->{$init} = $_[1];
  }
  else {
    $ret = $self->{Requests}->{$init};
    delete $self->{Requests}->{$init};
  }
  return $ret;
}

sub RSAVP1 {
  my ($pubkey, $r) = @_;
  my $e = $pubkey->e;
  my $n = $pubkey->n;
  my $c = Crypt::RSA::Primitives::mod_exp($r, $e, $n);
}

sub MGF1 {
    my ($seed, $masklen) = @_;
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

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(_rsa|_rsap|hashsize|hashalg|mgfhalg|blindsize|initsize)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
    return $self->{"\U$auto"};
  }
  else {
    croak "Could not AUTOLOAD method $auto.";
  }
}

1; # End of Crypt::RSA::Blind

package Crypt::RSA::Blind::PubKey;

use Compress::Zlib;

sub from_hex {
  Crypt::RSA::Key::Public->new->deserialize(String => [ uncompress(pack('H*',shift)) ]);
}

1; # End of Crypt::RSA::Blind::PubKey

package Crypt::RSA::Blind::SecKey;

use Compress::Zlib;

sub from_hex {
  Crypt::RSA::Key::Private->new->deserialize(String => [ uncompress(pack('H*',shift)) ]);
}

1; # End of Crypt::RSA::Blind::SecKey

__END__

=head1 NAME

Crypt::RSA::Blind - Blind RSA signatures

=head1 VERSION

 $Revision: 1.012 $
 $Date: Sun Jun 16 18:22:22 EST 2024 $

=cut

=head1 SYNOPSIS

    use Crypt::RSA::Blind;
    use Try::Tiny;

    my $rsab = new Crypt::RSA::Blind;

    my ($pubkey, $seckey) = $rsab->keygen(Size => 4096);

    my $msg = "Hello, world!";

    # RSABSSA-PSS interface (RFC 9747)

    my $slen = 48; # Salt length (in bytes). 0 for no salt.

    my ($blinded_msg, $blinding) = $rsab->ssa_blind (PublicKey => $pubkey,
                                                     Message => $msg,
                                                     sLen => $slen);

    my $blind_sig = $rsab->ssa_blind_sign(SecretKey => $seckey,
                                          BlindedMessage => $blinded_msg);

    my $sig = $rsab->ssa_finalize(PublicKey => $pubkey,
                                  BlindSig => $blind_sig,
                                  Blinding => $blinding,
                                  Message => $msg,
                                  sLen => $slen);

    print "OK\n" if try { $rsab->pss_verify(PublicKey => $pubkey,
                                            Signature => $sig,
                                            Message => $msg,
                                            sLen => $slen) };

    # Deprecated old interface

    my $init = $rsab->init;

    my $req = $rsab->request( Key => $pubkey,
                              Init => $init,
                              Message => $msg );

    my $blindsig = $rsab->sign( Key => $seckey, Plaintext => $req );

    my $sig = $rsab->unblind( Key => $pubkey, Init => $init,
                              Signature => $blindsig );

    print "OK\n" if $rsab->verify( Key => $pubkey, Message => $msg,
                                   Signature => $sig );

=head1 METHODS

=head2 new

Creates and returns a new Crypt::RSA::Blind object.

=head2 keygen

Generates and returns an RSA key-pair of specified bitsize. This is a
synonym for Crypt::RSA::Key::generate(). Parameters and return values
are described in the Crypt::RSA::Key(3) manpage.

=head2 init

Generates and returns an initialization vector.

The RSA blind signature protocol doesn't require the use of
initialization vectors. However, this module can use them to keep
track of the blinding factor for different signing requests, so it is
convenient to use initialization vectors when creating multiple
interlaved signing requests.

When using initialization vectors, the vector should be passed as the
'Init' named parameter to the ssa_blind() and ssa_finalize() methods
(in the old deprecated interface, to the req(), and unblind()
methods).

Alternately, you can keep track of the blinding factor for each
request in your own code. In this case, you can supply the blinding
factor as the 'Blinding' named parameter to the ssa_finalize() method,
instead of providing an initialization vector as the 'Init' parameter
to ssa_blind() and ssa_finalize().

Initialization vectors are not persistent across different invocations
of a script, so if you need to call ssa_blind() and ssa_finalize() in
different processes, you will need to record and persist the blinding
factor yourself.

=head2 ssa_blind

Generates and returns a blinded message for signing, and the blinding
factor used. The following named parameters are required:

=over

PublicKey - The public key of the signer

Message - The message to be blind signed

sLen - The length (in bytes) of the salt to be used in the RSABSSA-PSS
protocol. This can be 0 for no salt.

=back

The following optional named parameters can be provided:

=over

Init - An initialization vector from init()

R_inv - The r_inv value as an integer, for test vector verification.

Salt - A salt as a hex string without a leading '0x', for test vector
verification.

=back

Returns a list of two binary strings. The first is a the blinded
message for signing, the second is the blinding factor used. Raises an
exception on error.

=head2 ssa_blind_sign

Generates and returns a blind signature. The following named
parameters are required:

=over

SecretKey - The private key of the signer

BlindedMessage - The blinded message from ssa_blind()

=back

Returns the blind signature as a binary string. Raises an exception on
error.

=head2 ssa_finalize

Unblinds a blind signature and returns an RSASSA-PSS compatible
signature. The following named parameters are required:

=over

PublicKey - The public key of the signer

BlindSig - The blind signature from ssa_blindsign()

Message - The message that was provided to ssa_blind()

sLen - The lengh in bytes of the salt. 0 for no salt.

=back

In addition, one of the following parameters is required:

=over

Init - The initialization vector that was provided to ssa_blind()

Blinding - The blinding factor that was returned by ssa_blind()

=back

Returns the blind signature as a binary string. Raises an exception on
error.

=head2 pss_verify

Verify an RSABSSA-PSS signature. The following named parameters are
required:

=over

PublicKey - The public key of the signer

Signature - The blind signature

Message - The message that was signed

sLen - The lengh in bytes of the salt. 0 for no salt.

=back

Returns a true value if the signature verifies successfully. Raises an
exception on error.

=head2 ssa_randomize

Takes a single required parameter, the message to be signed, and
returns a prepared message with a random prefix.

=head2 errstr

Returns the error message from the last failed method call. See ERROR
HANDLING below for more details.

=head1 DEPRECATED METHODS

The methods below are deprecated and maintained for backwards
compatibility only. All new code should use the methods listed above.

=head2 request

Generates and returns a blind-signing request. The following named
parameters are required:

NOTE: This method is deprecated. Use the new ssa_blind method instead.

=over

Init - The initialization vector from init()

Key - The public key of the signer

Message - The message to be blind signed

=back

=head2 sign

Generates and returns a blind signature. The following named
parameters are required:

NOTE: This method is deprecated. Use the new ssa_blind_sign method
instead.

=over

Key - The private key of the signer

Plaintext - The blind-signing request

=back

=head2 unblind

Unblinds a blind signature and returns a verifiable signature. The
following named parameters are required:

NOTE: This method is deprecated. Use the new ssa_finalize method
instead.

=over

Init - The initialization vector from init()

Key - The public key of the signer

Signature - The blind signature

=back

=head2 verify

Verify a signature. The following named parameters are required:

NOTE: This method is deprecated. Use the new pss_verify method
instead.

=over

Key - The public key of the signer

Signature - The blind signature

Message - The message that was signed

=back

=head1 ACCESSORS

Accessors can be called with no arguments to query the value of an
object property, or with a single argument, to set the property to a
specific value (unless it is read-only).

=head2 hashalg

The name of the hashing algorithm to be used. Only SHA variants are
supported. The default is 'SHA384'.

=head2 mgfhalg

The name of the hashing algorithm to be used in the MGF1
function. Only SHA variants are supported. The default is 'SHA384'.

=head2 initsize

The bitsize of the init vector. Default is 128.

=head2 hashsize

The bitsize of the full-domain hash that will be generated from the
message to be blind-signed. Default is 768. This property is only
relevant to the old deprecated methods.

=head2 blindsize

The bitsize of the blinding factor. Default is 512. This property is
only relevant to the old deprecated methods.

=head1 ERROR HANDLING

Crypt::RSA::Blind relies on Crypt::RSA, which uses an error handling
method implemented in Crypt::RSA::Errorhandler. When a method fails
it returns undef and saves the error message. This error message is
available to the caller through the errstr() method. For more details
see the Crypt::RSA::Errorhandler(3) manpage.

Other than keygen(), all Crypt::RSA::Blind methods that report errors
this way are deprecated.

The ssa_* methods and pss_verify() do not use the above error
reporting method. They raise an exception on error.

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-rsab at hash.neo.email> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-rsa-blind at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-RSA-Blind>. 
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::RSA::Blind

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-RSA-Blind>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-RSA-Blind>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-RSA-Blind>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-RSA-Blind/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftware.ca/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
