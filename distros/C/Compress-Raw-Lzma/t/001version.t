BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict ;
use warnings ;

use Test::More ;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 5 + $extra ;

    use_ok('Compress::Raw::Lzma') ;
}

# Check lzma_version and LZMA_VERSION are the same.

SKIP: {
    skip "TEST_SKIP_VERSION_CHECK is set", 2
        if $ENV{TEST_SKIP_VERSION_CHECK};

    my $lzma_h  = LZMA_VERSION ;
    my $liblzma = Compress::Raw::Lzma::lzma_version_number;
    my $lzma_h_string  = LZMA_VERSION_STRING ;
    my $liblzma_string = Compress::Raw::Lzma::lzma_version_string;

    diag <<"EOM" ;

Compress::Raw::Lzma::VERSION                $Compress::Raw::Lzma::VERSION
Compress::Raw::Lzma::lzma_version_number    $liblzma
Compress::Raw::Lzma::lzma_version_string    $liblzma_string
LZMA_VERSION                                $lzma_h
LZMA_VERSION_STRING                         $lzma_h_string

EOM

    is($lzma_h_string, $liblzma_string, "LZMA_VERSION_STRING ($lzma_h_string) matches Compress::Raw::Lzma::lzma_version_string");
    is($lzma_h, $liblzma, "LZMA_VERSION ($lzma_h_string) matches Compress::Raw::Lzma::lzma_version")
        or diag <<EOM;

The version of lzma.h does not match the version of liblzma

You have lzma.h  version $lzma_h_string ($lzma_h)
     and liblzma version $liblzma_string ($liblzma)

You probably have two versions of lzma installed on your system.
Try removing the one you don't want to use and rebuild.
EOM
}


SKIP:
{
    # If running a github workflow that tests upstream tukaani-project/xz, check we have the version requested

    # Not github or not asking for explicit verson, so skip
    skip "Not github", 2
        if ! (defined $ENV{GITHUB_ACTION} && defined $ENV{LZMA_VERSION}) ;

    my $expected_version =  $ENV{LZMA_VERSION} ;
    # tag prefixes with a "v", so remove
    $expected_version =~ s/^v//i;

    $expected_version = '5.5.2beta'
        if $expected_version eq 'master';

    # skip "Skipping version tests for 'develop' branch", 7
    #     if ($expected_version eq 'develop') ;

    is Compress::Raw::Lzma::lzma_version_string(), $expected_version, "lzma_version_string() should be $expected_version";
    is LZMA_VERSION_STRING, $expected_version, "LZMA_VERSION_STRING should be $expected_version";

}
