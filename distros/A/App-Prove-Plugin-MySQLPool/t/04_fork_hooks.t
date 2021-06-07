use Test::More;
plan skip_all => 'mysql_install_db or mysqld --intiialize-insecure are not found'
    unless `which mysql_install_db 2>/dev/null` || `mysqld --verbose --help 2>/dev/null | grep '\\--initialize-insecure'`;
use strict;
use warnings;
use Test::Requires qw/DBI App::ForkProve/;

use FindBin;
use lib "$FindBin::RealBin/../";
use t::Util;

my $out = run_test({
    tests  => [ './t/plx/fork_hooks.plx' ],
    runner => 'forkprove', # this problem is occurred on forkprove only
});
exit_status_is( 0 )
    or diag "out = '$out'";

my (@dsns) = ( $out =~ m!dsn:(.+)$!gm );

is( (scalar @dsns), 2 )
    or diag explain { dsns => \@dsns, out => $out };
is( $dsns[ 0 ], $dsns[ 1 ], 'should not be re-assigned' )
    or diag explain { dsns => \@dsns, out => $out };

done_testing;
