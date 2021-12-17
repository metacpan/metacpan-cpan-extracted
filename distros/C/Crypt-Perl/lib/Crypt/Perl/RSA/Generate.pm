package Crypt::Perl::RSA::Generate;

=encoding utf-8

=head1 NAME

Crypt::Perl::RSA::Generate - RSA key generation

=head1 SYNOPSIS

    use Crypt::Perl::RSA::Generate ();

    #$prkey is a Crypt::Perl::RSA::PrivateKey instance.
    my $prkey = Crypt::Perl::RSA::Generate::create(2048);

=head1 DISCUSSION

Unfortunately, this is quite slow in Perl—too slow, in fact, if you
don’t have either L<Math::BigInt::GMP> or L<Math::BigInt::Pari>.
The logic here will still run under pure Perl, but it’ll take too long
to be practical.

The current L<Math::ProvablePrime> backend is slated to be replaced
with L<Math::Prime::Util>; once that happens, pure-Perl operation should
be much more feasible.

=head1 ALTERNATIVES

=over 4

=item L<Crypt::OpenSSL::RSA> - probably the fastest way to generate RSA
keys in perl. (It relies on XS, so this project can’t use it.)

=item Use the C<openssl> binary L<OpenSSL|http://openssl.org> directly,
e.g., C<my $rsa_pem = qx/openssl genrsa/>. Most *NIX systems can do this.

=back

NOTE: As of December 2016, L<Crypt::PK::RSA> is NOT suitable for key
generation because it can only generate keys with up to a 512-bit modulus.

=cut

use strict;
use warnings;

use Math::ProvablePrime ();

use Crypt::Perl::BigInt ();
use Crypt::Perl::RSA::PrivateKey ();
use Crypt::Perl::X ();

use constant PUBLIC_EXPONENTS => ( 65537, 3 );

sub create {
    my ($mod_bits, $exp) = @_;

    die Crypt::Perl::X::create('Generic', "Need modulus length!") if !$mod_bits;

    $exp ||= (PUBLIC_EXPONENTS())[0];

    if (!grep { $exp eq $_ } PUBLIC_EXPONENTS()) {
        my @allowed = PUBLIC_EXPONENTS();
        die Crypt::Perl::X::create('Generic', "Invalid public exponent ($exp); should be one of: [@allowed]");
    }

    my $qs = $mod_bits >> 1;
    (ref $exp) or $exp = Crypt::Perl::BigInt->new($exp);

    while (1) {
        my ($p, $q, $p1, $q1);

        #Create a random number, ($mod_bits - $qs) bits long.
        {
            $p = _get_random_prime($mod_bits - $qs);
            $p1 = $p->copy()->bdec();

            #($p - 1) needs not to be a multiple of $exp
            redo if $p1->copy()->bmod($exp)->is_zero();
        }

        {
            $q = _get_random_prime($qs);
            $q1 = $q->copy()->bdec();

            #Same restriction as on $p applies to $q.
            #Let’s also make sure these are two different numbers!
            redo if $q1->copy()->bmod($exp)->is_zero() || $q->beq($p);
        }

        #$p should be > $q
        if ($p->blt($q)) {
            my $t = $p;
            $p = $q;
            $q = $t;

            $t = $p1;
            $p1 = $q1;
            $q1 = $t;
        }

        my $phi = $p1->copy()->bmul($q1);

        my $d = $exp->copy()->bmodinv($phi);

        my $obj = Crypt::Perl::RSA::PrivateKey->new(
            {
                version => 0,
                modulus => $p->copy()->bmul($q),
                publicExponent => $exp,
                privateExponent => $d,
                prime1 => $p,
                prime2 => $q,
                exponent1 => $d->copy()->bmod($p1),
                exponent2 => $d->copy()->bmod($q1),
                coefficient => $q->copy()->bmodinv($p),
            },
        );

        return $obj;
    }
}

sub _get_random_prime {
    my @got = Math::ProvablePrime::find(@_);
    return Crypt::Perl::BigInt->new(@got);
}

1;
