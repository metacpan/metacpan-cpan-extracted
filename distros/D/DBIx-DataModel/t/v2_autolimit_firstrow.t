use strict;
use warnings;

use SQL::Abstract::More;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;


# setup schema
HR->singleton->autolimit_firstrow(1);
HR_connect;


HR->table('Employee')->select(
  -result_as => 'firstrow',
 );
sqlLike("SELECT * FROM T_Employee LIMIT ? OFFSET ?",
        [1, 0],
        "autolimit");

done_testing;

