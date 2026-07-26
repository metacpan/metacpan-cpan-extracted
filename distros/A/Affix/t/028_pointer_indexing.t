use v5.40;
use lib 'lib', 'blib/arch', 'blib/lib';
use blib;
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
#
my $ptr = cast( calloc( 4, sizeof sizeof( Array [ Int, 4 ] ) ), Array [ Int, 4 ] );

# Test FETCH
is $ptr->[0], 0, 'FETCH index 0';
is $ptr->[3], 0, 'FETCH index 3';
Affix::dump( $ptr, sizeof( Array [ Int, 4 ] ) );

# Test STORE
$ptr->[0] = 42;
$ptr->[3] = 123;
Affix::dump( $ptr, sizeof( Array [ Int, 4 ] ) );
is $ptr->[0], 42,  'Read back index 0';
is $ptr->[3], 123, 'Read back index 3';
is $ptr->[0], 42,  'Value in arrayref matches';
Affix::dump( $ptr, sizeof( Array [ Int, 4 ] ) );
diag Affix::raw( $ptr, sizeof( Array [ Int, 4 ] ) );
use Data::Dump;
is Affix::raw( $ptr, sizeof( Array [ Int, 4 ] ) ), "*\0\0\0\0\0\0\0\0\0\0\0{\0\0\0", 'raw';
#
done_testing;
