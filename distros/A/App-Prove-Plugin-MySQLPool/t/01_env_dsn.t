use Test::More;
plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;
use strict;
use warnings;

use t::Util;

my $out = run_test({
    tests => [ 't/plx/1.plx', 't/plx/2.plx' ],
});
exit_status_is( 0 );

my (@dsns) = ( $out =~ m!dsn:(.+)$!gm );

is( (scalar @dsns), 2 );
isnt( $dsns[ 0 ], $dsns[ 1 ] );

done_testing;
