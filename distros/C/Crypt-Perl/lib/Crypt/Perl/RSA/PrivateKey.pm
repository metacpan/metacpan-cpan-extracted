package Crypt::Perl::RSA::PrivateKey;

=encoding utf-8

=head1 NAME

Crypt::Perl::RSA::PrivateKey - object representation of an RSA private key

=head1 SYNOPSIS

    #You’ll probably instantiate this class using Parser.pm
    #or Generate.pm.

    #cf. JSON Web Algorithms (RFC 7518, page 5)
    #These return an octet string.
    $sig = $prkey->sign_RS256($message);
    $sig = $prkey->sign_RS384($message);
    $sig = $prkey->sign_RS512($message);

    #These return 1 or 0 to indicate verification or non-verification.
    $prkey->verify_RS256($message, $sig);
    $prkey->verify_RS384($message, $sig);
    $prkey->verify_RS512($message, $sig);

    #----------------------------------------------------------------------

    my $enc = $prkey->encrypt_raw($payload);
    my $orig = $prkey->decrypt_raw($enc);

    #----------------------------------------------------------------------

    my $der = $prkey->to_der();
    my $pem = $prkey->to_pem();

    #For use in creating PKCS #10 CSRs and X.509 certificates
    my $pub_der = $prkey->to_subject_public_der();

    my $pbkey = $prkey->get_public_key();

    #----------------------------------------------------------------------

    $prkey->version();              #scalar, integer

    $prkey->size();                 #modulus length, in bits
    $prkey->modulus_byte_length();

    #----------------------------------------------------------------------
    # The following all return instances of Crypt::Perl::BigInt,
    # a subclass of Math::BigInt.
    # The pairs (e.g., modulus() and N()) are aliases.
    #----------------------------------------------------------------------

    $prkey->modulus();
    $prkey->N();

    $prkey->publicExponent();
    $prkey->E();

    $prkey->privateExponent();
    $prkey->D();

    $prkey->prime1();
    $prkey->P();

    $prkey->prime2();
    $prkey->Q();

    $prkey->exponent1();
    $prkey->DP();

    $prkey->exponent2();
    $prkey->DQ();

    $prkey->coefficient();
    $prkey->QINV();

=cut

use strict;
use warnings;

use parent qw(
    Crypt::Perl::RSA::KeyBase
);

use Module::Load ();

use Crypt::Perl::RNG ();
use Crypt::Perl::X ();

use constant _PEM_HEADER => 'RSA PRIVATE KEY';
use constant _ASN1_MACRO => 'RSAPrivateKey';

BEGIN {
    __PACKAGE__->mk_ro_accessors(
        qw(
        version
        publicExponent
        privateExponent
        prime1
        prime2
        exponent1
        exponent2
        coefficient
        )
    );

    *E = \&publicExponent;
    *D = \&privateExponent;

    *P = \&prime1;
    *Q = \&prime2;

    *DP = \&exponent1;
    *DQ = \&exponent2;

    *QINV = \&coefficient;

    *to_subject_public_der = __PACKAGE__->can('_to_subject_public_der');
}

sub sign_RS256 {
    my ($self, $msg) = @_;

    return $self->_sign($msg, 'Digest::SHA', 'sha256', 'PKCS1_v1_5');
}

sub sign_RS384 {
    my ($self, $msg) = @_;

    return $self->_sign($msg, 'Digest::SHA', 'sha384', 'PKCS1_v1_5');
}

sub sign_RS512 {
    my ($self, $msg) = @_;

    return $self->_sign($msg, 'Digest::SHA', 'sha512', 'PKCS1_v1_5');
}

sub get_public_key {
    my ($self) = @_;

    require Crypt::Perl::RSA::PublicKey;

    return Crypt::Perl::RSA::PublicKey->new( {
        modulus => $self->{'modulus'},
        publicExponent => $self->{'publicExponent'},
    } );
}

sub get_struct_for_private_jwk {
    my ($self) = @_;

    require MIME::Base64;

    my $jwk = $self->get_struct_for_public_jwk();

    my %augment = qw(
        d   D
        p   P
        q   Q
        dp  DP
        dq  DQ
        qi  QINV
    );

    for my $k (keys %augment) {
        my $accessor = $augment{$k};
        $jwk->{$k} = MIME::Base64::encode_base64url( $self->$accessor()->as_bytes() );
    }

    return $jwk;
}

#----------------------------------------------------------------------
#This function, in tandem with encrypt_raw(), represents the fundamental
#mathematical truth on which RSA rests.
#

sub decrypt_raw {
    my ($self, $x) = @_;

    $x = Crypt::Perl::BigInt->from_bytes($x);

    #jsrsasign avoids this when it has P and Q, which we have.
    #presumably that’s because privateExponent (D) is quite large,
    #so using it as an exponent is expensive.
    #return $self->bmodpow($self->{'privateExponent'}, $self->{'modulus'})->as_bytes();

    my $p = $self->P();
    my $q = $self->Q();

    my $p1 = $p->copy()->bdec();
    my $q1 = $q->copy()->bdec();

    my $xp = $x->copy()->bmod($p)->bmodpow( $self->D()->copy()->bmod($p1), $p );
    my $xq = $x->copy()->bmod($q)->bmodpow( $self->D()->copy()->bmod($q1), $q );

    #$xp->binc($p) while $xp->blt($xq);

    #return ($xq + ((($xp - $xq) * $self->QINV()) % $p) * $q)->as_bytes();

    my $diff = $xp->bsub($xq)->babs()->bmod($p)->bsub($p)->babs();

    $diff->bmul($self->QINV())->bmod($p)->bmuladd($q, $xq)->as_bytes();
}

#----------------------------------------------------------------------

sub _sign {
    my ($self, $msg, $hash_module, $hasher, $scheme) = @_;

    Module::Load::load($hash_module);

    my $dgst = $hash_module->can($hasher)->($msg);

    my $sig;

    if ($scheme eq 'PKCS1_v1_5') {
        require Crypt::Perl::RSA::PKCS1_v1_5;

        my $sig_length = $self->modulus_byte_length();

        #The encoded length equals the length, in bytes,
        #of the key’s modulus.
        my $eb = Crypt::Perl::RSA::PKCS1_v1_5::encode(
            $dgst,
            $hasher,
            $sig_length,
        );

        #printf "PERL: %v02x\n", $eb;
        #print "mod byte length: " . Crypt::Perl::RSA::modulus_byte_length($key_obj) . $/;

        my $x = Crypt::Perl::BigInt->from_hex( unpack 'H*', $eb );

        $sig = $self->_transform($x)->as_bytes();

        substr( $sig, 0, 0 ) = "\0" x ($sig_length - length $sig);
    }
    else {
        die Crypt::Perl::X::create('Generic', "Unknown RSA signature scheme: “$scheme”");
    }

    return $sig;
}

#RSA’s signing operation.
#This function is based on _modPow() in forge’s js/rsa.js.
#
#Returns a BigInt.
sub _transform {
    my ($self, $x) = @_;

    my $key_bytes_length = $self->modulus_byte_length();

    #cryptographic blinding
    my $r;
    do {
        $r = Crypt::Perl::BigInt->from_hex(
            Crypt::Perl::RNG::bytes_hex( $key_bytes_length ),
        );
    } while ($r->bge($self->N())) || ($r->bgcd($self->N())->bne(1));

    $x->bmul( $r->copy()->bmodpow($self->E(), $self->N()) )->bmod($self->N());

    #calculate xp and xq
    my $xp = $x->copy()->bmod($self->P())->bmodpow($self->DP(), $self->P());
    my $xq = $x->copy()->bmod($self->Q())->bmodpow($self->DQ(), $self->Q());

    #xp must be larger than xq to avoid signed bit usage
    $xp->badd($self->P()) while $xp->blt($xq);

    my $y = $xp->bsub($xq)->bmul($self->QINV())->bmod($self->P());

    #$y *= $self->Q();
    #$y += $xq;
    $y->bmuladd( $self->Q(), $xq );

    #remove effect of random for cryptographic blinding
    $y->bmul( $r->bmodinv($self->N()) );
    $y->bmod($self->N());

    return $y;
}

1;
