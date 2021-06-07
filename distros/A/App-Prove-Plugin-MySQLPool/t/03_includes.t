use Test::More;
plan skip_all => 'mysql_install_db or mysqld --intiialize-insecure are not found'
    unless `which mysql_install_db 2>/dev/null` || `mysqld --verbose --help 2>/dev/null | grep '\\--initialize-insecure'`;
use strict;
use warnings;
use Test::Requires qw/DBI/;

use FindBin;
use lib "$FindBin::RealBin/../";
use t::Util;

my $out = run_test({
    tests    => [ 't/plx/prepare.plx' ],
    preparer => 'Util',
    includes => 't/lib',
});
exit_status_is( 0 )
    or diag "out = '$out'";

done_testing;
