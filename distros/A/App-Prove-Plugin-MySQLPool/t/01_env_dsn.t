use Test::More;
plan skip_all => 'mysql_install_db or mysqld --intiialize-insecure are not found'
    unless `which mysql_install_db 2>/dev/null` || `mysqld --verbose --help 2>/dev/null | grep '\\--initialize-insecure'`;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../";
use t::Util;

my $out = run_test({
    tests => [ 't/plx/1.plx', 't/plx/2.plx' ],
});
exit_status_is( 0 )
    or diag "out = '$out'";

my (@dsns) = ( $out =~ m!dsn:(.+)$!gm );

is( (scalar @dsns), 2 )
    or diag explain { dsns => \@dsns, out => $out };
isnt( $dsns[ 0 ], $dsns[ 1 ] )
    or diag explain { dsns => \@dsns, out => $out };

done_testing;
