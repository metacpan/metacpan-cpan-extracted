package t::Crypt::Perl::PKCS10;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use File::Temp;

use lib "$FindBin::Bin/lib";

use OpenSSL_Control ();

use parent qw(
    TestClass
    NeedsOpenSSL
);

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::Ed25519::PrivateKey ();
use Crypt::Perl::PK ();
use Crypt::Perl::X509::Name ();

use Crypt::Perl::PKCS10 ();

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
        'test_new',
        (4 + @{ [ keys %Crypt::Perl::X509::Name::_OID ] }) * @{ [ $self->_KEY_TYPES_TO_TEST() ] },
    );

    return $self;
}

sub _KEY_TYPES_TO_TEST {
    my ($self) = @_;

    my @types = (
        1024,
        2048,
    );

    if ( OpenSSL_Control::can_ecdsa() ) {
        push @types, (
            'secp224k1',
            'brainpoolP256r1',
            'secp384r1',
            'secp521r1',
            'prime239v1',
            'brainpoolP320r1',
            'brainpoolP512r1',
        );
    }

    if ( OpenSSL_Control::can_ed25519() ) {
        push @types, 'ed25519';
    }

    return @types;
}

sub test_new : Tests() {
    my ($self) = @_;

    my $ossl_bin = OpenSSL_Control::openssl_bin ();

    for my $type ( $self->_KEY_TYPES_TO_TEST() ) {
        my $key;

        my $print_type;

        if ($type =~ m<\A[0-9]>) {
            $key = Crypt::Perl::PK::parse_key( scalar qx<$ossl_bin genrsa $type> );
            $print_type = "RSA ($type-bit)";
        }
        elsif ($type eq 'ed25519') {
            $key = Crypt::Perl::Ed25519::PrivateKey->new();
            $print_type = 'ed25519';
        }
        else {
            $key = Crypt::Perl::ECDSA::Generate::by_curve_name($type);
            $print_type = "ECDSA ($type)";
        }

        my $pkcs10 = Crypt::Perl::PKCS10->new(
            key => $key,
            subject => [
                map { $_ => "the_$_" } keys %Crypt::Perl::X509::Name::_OID
            ],
            attributes => [
                [ 'challengePassword' => 'iNsEcUrE' ],
                [ 'extensionRequest',
                    [ 'subjectAltName',
                        [ dNSName => 'felipegasper.com' ],
                        [ dNSName => 'gasperfelipe.com' ],
                    ],
                ],
            ],
        );

        my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$fh} $pkcs10->to_pem() or die $!;
        close $fh;

        my $text = qx<$ossl_bin req -text -noout -in $fpath>;

        SKIP: {
            if ( $key->isa('Crypt::Perl::ECDSA::PrivateKey') ) {
                skip 'Your OpenSSL can’t load this key!', 1 if !OpenSSL_Control::can_load_private_pem($key->to_pem_with_curve_name());
            }

            unlike( $text, qr<Unable to load>, "$print_type: key parsed correctly" ) or do {
                print $key->to_pem_with_curve_name() . $/;
            };
        }

        for my $subj_part (sort keys %Crypt::Perl::X509::Name::_OID) {
            like( $text, qr/\s*=\s*the_\Q$subj_part\E/, "$print_type: $subj_part" );
        }

        like( $text, qr<DNS:felipegasper\.com>, "$print_type: SAN 1" );
        like( $text, qr<DNS:gasperfelipe\.com>, "$print_type: SAN 2" );

        #Some OpenSSL versions hide the challengePassword on CSR parse,
        #so pass it through a generic ASN.1 parse instead.
        $text = qx<$ossl_bin asn1parse -dump -in $fpath>;
        like( $text, qr/challengePassword.*iNsEcUrE/s, "$print_type: challengePassword" );
    }

    return;
}

1;
