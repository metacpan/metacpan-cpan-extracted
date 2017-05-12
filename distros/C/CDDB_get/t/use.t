#!/usr/bin/env perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use Test::More;

my $result;
BEGIN {
    $result = use_ok("CDDB_get");
}

ok( $result, "use_ok() ran" );
done_testing(2);

