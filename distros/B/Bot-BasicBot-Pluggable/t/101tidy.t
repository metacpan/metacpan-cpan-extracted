use strict;

use warnings;
use File::Spec;
use Test::More;
use Try::Tiny;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

try {
    require Test::PerlTidy;
}
catch {
    my $msg = 'Test::PerlTidy required to criticise code';
    plan( skip_all => $msg );
};

Test::PerlTidy::run_tests();
