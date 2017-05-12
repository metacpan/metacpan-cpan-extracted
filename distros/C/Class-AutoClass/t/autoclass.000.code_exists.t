#!perl
use strict;
use Test::More tests => 2;
# make sure all the necesary modules exist
BEGIN {
    use_ok( 'Class::AutoClass' );
    use_ok( 'Class::AutoClass::Root' );
}
diag( "Testing Class::AutoClass $Class::AutoClass::VERSION, Perl $], $^X" );
done_testing();
