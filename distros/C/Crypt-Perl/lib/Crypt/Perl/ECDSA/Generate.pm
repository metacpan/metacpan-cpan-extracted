package Crypt::Perl::ECDSA::Generate;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::Generate - ECDSA key generation

=head1 SYNOPSIS

    use Crypt::Perl::ECDSA::Generate ();

    #$prkey is a C::P::E::PrivateKey instance.
    my $prkey = Crypt::Perl::ECDSA::Generate::by_curve_name('secp521r1');

    my $signature = $prkey->sign('Hello!');

    die 'Wut' if $prkey->verify('Hello!', $signature);

    #You can also, in case it’s useful, do this. It’s probably
    #only useful if you’re developing a new curve or something … ??
    my $prkey2 = Crypt::Perl::ECDSA::Generate::by_explicit_curve(
        {
            p => Crypt::Perl::BigInt->new(...),
            a => ...,
            b => ...,
            n => ...,
            h => ...,
            gx => ...,
            gy => ...,
        },
    );

=head1 DISCUSSION

Thankfully, this is easy enough on processors that it’s feasible
in pure Perl!

=cut

use strict;
use warnings;

use Crypt::Perl::BigInt ();
use Crypt::Perl::Math ();
use Crypt::Perl::RNG ();
use Crypt::Perl::ECDSA::EC::DB ();
use Crypt::Perl::ECDSA::EC::Curve ();
use Crypt::Perl::ECDSA::PrivateKey ();

#The curve name is optional; if given, only the name will be encoded
#into the key rather than the explicit curve parameters.
sub by_curve_name {
    my ($curve_name) = @_;

    my $key_parts = _generate(
        Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve_name),
    );

    return Crypt::Perl::ECDSA::PrivateKey->new_by_curve_name($key_parts, $curve_name);
}

*by_name = *by_curve_name;  #legacy

sub by_explicit_curve {
    my ($curve_hr) = @_;

    my $key_parts = _generate($curve_hr);

    return Crypt::Perl::ECDSA::PrivateKey->new($key_parts, $curve_hr);
}

#from generateKeyPairHex() in jsrsasign
sub _generate {
    my ($curve_hr) = @_;

    my $biN = $curve_hr->{'n'};

    my $biPrv = Crypt::Perl::Math::randint( $biN );

    #my $G = '04' . join(q<>, map { substr( $_->as_hex(), 2 ) } @{$curve}{'gx','gy'});
    #$G = Crypt::Perl::BigInt->from_hex($full_g);

    my $curve = Crypt::Perl::ECDSA::EC::Curve->new( @{$curve_hr}{'p', 'a', 'b'} );

    my $G = $curve->decode_point( @{$curve_hr}{'gx','gy'});

    my $epPub = $G->multiply($biPrv);
    my $biX = $epPub->get_x()->to_bigint();
    my $biY = $epPub->get_y()->to_bigint();

    my $key_hex_len = 2 * Crypt::Perl::Math::ceil( $curve->keylen() / 8 );

    my ($hx, $hy) = map { substr( $_->as_hex(), 2 ) } $biX, $biY;

    $_ = sprintf "%0${key_hex_len}s", $_ for ($hx, $hy);

    my $biPub = Crypt::Perl::BigInt->from_hex("04$hx$hy");

    return {
        version => 0,
        private => $biPrv,
        public => $biPub,
    };
}

#sub generate {
#    my ($curve_name) = @_
#
#    my $curve_hr = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve_name);
#
#    my $bytes = $curve_hr->{'n'}->as_hex() / 2 - 1;
#    my $ns2 = $curve_hr->{'n'} - 2;
#
#    do {
#        my $priv = _gen_bignum($bytes);
#        next if $priv > $ns2;
#
#        $priv += 1;
#
#        return _key_from_private($curve_hr, $priv);
#    } while 1;
#}
#
#sub _key_from_private {
#    return _keypair( $curve_hr, $priv );
#}
#
#sub _keypair {
#    my ($curve_hr, $priv) = @_;
#
#    $priv %= $curve_hr->{'n'};
#
#    my $full_g = '04' . join(q<>, map { substr( $_->as_hex(), 2 ) } @{$curve}{'gx','gy'});
#    $full_g = Crypt::Perl::BigInt->from_hex($full_g);
#
#    return {
#        priv => $priv,
#        pub => $full_g * $priv,
#    };
#}
#
#sub _gen_bignum {
#    my ($bits) = @_;
#
#    return Crypt::Perl::BigInt->from_bin( Crypt::Perl::RNG::bit_string($bits) );
#}

1;
