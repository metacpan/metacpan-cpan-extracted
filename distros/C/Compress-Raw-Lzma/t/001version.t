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

    plan tests => 2 + $extra ;

    use_ok('Compress::Raw::Lzma') ; 
}

# Check lzma_version and LZMA_VERSION are the same.

SKIP: {
    skip "TEST_SKIP_VERSION_CHECK is set", 1 
        if $ENV{TEST_SKIP_VERSION_CHECK};
    my $lzma_h  = LZMA_VERSION ;
    my $liblzma = Compress::Raw::Lzma::lzma_version_number;
    my $lzma_h_string  = LZMA_VERSION_STRING ;
    my $liblzma_string = Compress::Raw::Lzma::lzma_version_string;

    is($lzma_h, $liblzma, "LZMA_VERSION ($lzma_h_string) matches Compress::Raw::Lzma::lzma_version")
        or diag <<EOM;

The version of lzma.h does not match the version of liblzma
 
You have lzma.h  version $lzma_h_string ($lzma_h)
     and liblzma version $liblzma_string ($liblzma)
 
You probably have two versions of lzma installed on your system.
Try removing the one you don't want to use and rebuild.
EOM
}

