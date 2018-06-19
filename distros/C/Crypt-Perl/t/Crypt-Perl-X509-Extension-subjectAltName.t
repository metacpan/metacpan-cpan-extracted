package t::Crypt::Perl::X509::Extension::subjectAltName;

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
use parent qw( TestClass );

use Crypt::Perl::X509::Extension::subjectAltName ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_encode : Tests(1) {
    my $vector_str = '30.12.82.07.66.6f.6f.2e.63.6f.6d.82.07.62.61.72.2e.63.6f.6d';

    my $san_obj = Crypt::Perl::X509::Extension::subjectAltName->new(
        [ dNSName => 'foo.com' ],
        [ dNSName => 'bar.com' ],
    );

    my $san_enc = $san_obj->encode();

    is(
        sprintf( '%v.02x', $san_enc ),
        $vector_str,
        'encode() as expected - two dNSName entries',
    );

    return;
}

sub test_encode_legacy_format : Tests(1) {
    my $vector_str = '30.12.82.07.66.6f.6f.2e.63.6f.6d.82.07.62.61.72.2e.63.6f.6d';

    my $san_obj = Crypt::Perl::X509::Extension::subjectAltName->new(
        dNSName => 'foo.com',
        dNSName => 'bar.com',
    );

    my $san_enc = $san_obj->encode();

    is(
        sprintf( '%v.02x', $san_enc ),
        $vector_str,
        'encode() as expected - two dNSName entries',
    );

    return;
}

1;
