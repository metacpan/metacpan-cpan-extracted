#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Class::Unload' );
}

diag( "Testing Class::Unload $Class::Unload::VERSION, Perl $], $^X" );

done_testing;
