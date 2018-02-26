use strict;
use warnings;

use SQL::Abstract::More;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;

# setup the schema
my $sqlam = SQL::Abstract::More->new(array_datatypes => 1);
HR->singleton->sql_abstract($sqlam);
HR_connect;

# data for tests
my $emp_id = 9876;
my $food   = [qw/potatoes tomatoes/];

# update
HR->table('Employee')->update($emp_id, {food => $food});
sqlLike("UPDATE T_Employee SET food = ? WHERE ( emp_id = ? )",
        [$food, $emp_id],
        "update array datatype");

# insert
HR->table('Employee')->insert({emp_id => $emp_id, food => $food});
sqlLike("INSERT INTO T_Employee(emp_id, food) VALUES (?, ?)",
        [$emp_id, $food],
        "insert array datatype");

done_testing;
