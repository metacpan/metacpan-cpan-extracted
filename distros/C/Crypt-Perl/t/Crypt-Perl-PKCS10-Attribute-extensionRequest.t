package t::Crypt::Perl::PKCS10::Attribute::extensionRequest;

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

use lib "$FindBin::Bin/lib";

use parent qw(
    TestClass
);

use Crypt::Perl::X509::Extension::subjectAltName ();

use Crypt::Perl::PKCS10::Attribute::extensionRequest ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_encode : Tests(2) {
    my $vector_str = '30.1d.30.1b.06.03.55.1d.11.04.14.30.12.82.07.66.6f.6f.2e.63.6f.6d.82.07.62.61.72.2e.63.6f.6d';

    my $san_obj = Crypt::Perl::X509::Extension::subjectAltName->new(
        [ dNSName => 'foo.com' ],
        [ dNSName => 'bar.com' ],
    );

    my $ext_r_obj = Crypt::Perl::PKCS10::Attribute::extensionRequest->new($san_obj);

    my $ext_r_enc = $ext_r_obj->encode();

    is(
        sprintf( '%v.02x', $ext_r_enc ),
        $vector_str,
        'encode() as expected - subjectAltName with two dNSName entries',
    );

    #----------------------------------------------------------------------

    $vector_str = '30.20.30.1e.06.03.55.1d.11.01.01.ff.04.14.30.12.82.07.66.6f.6f.2e.63.6f.6d.82.07.62.61.72.2e.63.6f.6d';

    my $crit_obj = Crypt::Perl::PKCS10::Attribute::extensionRequest->new(
        {
            extension => $san_obj,
            critical => 1,
        },
    );

    my $crit_enc = $crit_obj->encode();

    is(
        sprintf( '%v.02x', $crit_enc ),
        $vector_str,
        'encode() as expected - critical subjectAltName with two dNSName entries',
    );

    return;
}

1;
