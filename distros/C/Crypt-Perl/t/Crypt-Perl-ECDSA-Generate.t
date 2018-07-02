package t::Crypt::Perl::ECDSA::Generate;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use Try::Tiny;

use FindBin;

use lib "$FindBin::Bin/lib";
use OpenSSL_Control ();

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Crypt::Format ();
use Digest::SHA ();
use File::Slurp ();
use File::Temp ();
use IPC::Open3 ();
use Symbol::Get ();

use Crypt::Perl::ECDSA::EC::CurvesDB ();
use Crypt::Perl::ECDSA::EC::DB ();

use parent qw( TestClass );

use OpenSSL_Control ();

use lib "$FindBin::Bin/../lib";

use Crypt::Perl::ECDSA::Generate ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->num_method_tests(
        'test_generate',
        (4 * @{ [ $self->_KEY_TYPES_TO_TEST() ] }),
    );

    return $self;
}

#Should this logic Go into EC::DB, to harvest all working
#curve names?
sub _KEY_TYPES_TO_TEST {
    my @names = Symbol::Get::get_names('Crypt::Perl::ECDSA::EC::CurvesDB');

    my @curves;
    for my $name (sort @names) {
        next if $name !~ m<\AOID_(.+)>;

        my $curve = $1;

        try {
            Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name($curve);
            push @curves, $curve;
        }
        catch {
            diag( sprintf "Skipping “$curve” (%s) …", ref $_ );
        };
    }

    return @curves;
}

sub test_legacy_alias : Tests(1) {
    is(
        \&Crypt::Perl::ECDSA::Generate::by_name,
        \&Crypt::Perl::ECDSA::Generate::by_curve_name,
        'by_name() alias',
    );
}

sub test_generate : Tests() {
    my ($self) = @_;

    diag "XXX NOTE: This test can take a while and/or spew a lot of text.";

    my $msg = rand;

    my $ossl_bin = OpenSSL_Control::openssl_bin();
    my $ossl_has_ecdsa = $ossl_bin && OpenSSL_Control::can_ecdsa();

    #Use SHA1 since it’s the smallest digest that the latest OpenSSL accepts.
    my $dgst = Digest::SHA::sha1($msg);
    my $digest_alg = 'sha1';

    my @ossl_curves = $ossl_has_ecdsa ? OpenSSL_Control::curve_names() : ();

    for my $curve ( $self->_KEY_TYPES_TO_TEST() ) {
        diag "curve: $curve";

        my $key_obj = Crypt::Perl::ECDSA::Generate::by_curve_name($curve);

        isa_ok(
            $key_obj,
            'Crypt::Perl::ECDSA::PrivateKey',
            "$curve: return of by_curve_name()",
        );

      SKIP: {
            skip 'No OpenSSL ECDSA support!', 1 if !$ossl_has_ecdsa;

            if (!grep { $curve eq $_ } @ossl_curves) {
                skip "Your OpenSSL doesn’t support this curve ($curve).", 1;
            }

            my ($fh, $path) = File::Temp::tempfile( CLEANUP => 1 );
            print {$fh} $key_obj->to_pem_with_explicit_curve() or die $!;
            close $fh;

            system( "$ossl_bin ec -text -in $path -out $path.out" );

            my $parsed = File::Slurp::read_file("$path.out");

            ok( !$?, "$curve: OpenSSL parses OK" ) or diag $parsed;
        }

      SKIP: {
            try {
                my $sig = $key_obj->sign($dgst);

                ok( $key_obj->verify( $dgst, $sig ), 'verify() on own signature' );

              SKIP: {
                    skip 'No OpenSSL ECDSA support!', 1 if !$ossl_has_ecdsa;

                    if (!grep { $curve eq $_ } @ossl_curves) {
                        skip "Your OpenSSL doesn’t support this curve ($curve).", 1;
                    }

                    skip 'Your OpenSSL can’t correct verify an ECDSA digest against a private key!', 1 if OpenSSL_Control::has_ecdsa_verify_private_bug();

                    # This used to use explicit curves, but certain older
                    # OpenSSL releases can’t verify digests with those.
                    my $key_pem = $key_obj->to_pem_with_curve_name();

                    ok(
                        OpenSSL_Control::verify_private(
                            $key_pem,
                            $msg,
                            $digest_alg,
                            $sig,
                        ),
                        "$curve: OpenSSL verifies signature ($digest_alg) of ($msg)",
                    ) or print "$key_pem\n";
                }
            }
            catch {
                if ( try { $_->isa('Crypt::Perl::X::TooLongToSign') } ) {
                    skip $_->to_string(), 2;
                }
                else {
                    local $@ = $_; die;
                }
            };
        }
    }

    return;
}

1;
