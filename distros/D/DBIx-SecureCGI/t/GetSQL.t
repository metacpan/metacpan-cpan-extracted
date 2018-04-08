use lib 't';
use share;

plan tests => 84;

my $cv;
my $SQL;
ok my $dbh = new_adbh;
ok my $table1 = new_table "id_t1 $PK, i INT";
ok my $table2 = new_table "id_t2 $PK, id_t1 INT, s VARCHAR(255)";
ok my $table3 = new_table "id_t3 $PK, id_t1 INT, id_t2 INT, d DATETIME";
ok my $table4 = new_table "id_t4 $PK, id_t2 INT, i INT";
ok my $table5 = new_table "id_t5 $PK, i INT";
ok my $table6 = new_table "i INT";

# TableInfo fail
ok !$dbh->GetSQL([$table1,$table6,$table2], {});
ok $dbh->err;
like $dbh->errstr, qr/primary key/;
$dbh->set_err(undef,undef);
$dbh->GetSQL([], {}, $cv = AE::cv);
ok !$cv->recv;
ok $dbh->err;
like $dbh->errstr, qr/bad tables:/;

# define JOIN type
ok $dbh->GetSQL(["$table1 LEFT","$table2 LEFT","$table3  INNER  "], {});
ok !$dbh->GetSQL(["$table1 LEFT","$table2 LEFT","$table3  INER  "], {});
ok $dbh->err;
like $dbh->errstr, qr/unknown join type/;
$dbh->set_err(undef,undef);
ok !$dbh->err;
$dbh->GetSQL(["$table1 LEFT","$table2 LEFT","$table3  INER  "], {}, $cv = AE::cv);
ok !$cv->recv;
ok $dbh->err;
like $dbh->errstr, qr/unknown join type/;

# {Table}, {ID}
$SQL = $dbh->GetSQL(["$table1 LEFT","$table2 LEFT","$table3  INNER  "], {});
is $SQL->{Table}, $table1, '{Table}';
is $SQL->{ID}, 'id_t1', '{ID}';

# {From}
is $SQL->{From},
    "`$table1`"
  .  " LEFT JOIN `$table2` ON (`$table2`.`id_t1` = `$table1`.`id_t1`)"
  . " INNER JOIN `$table3` ON (`$table3`.`id_t1` = `$table1`.`id_t1`)"
  , '{From}';
ok !$dbh->GetSQL([$table1,$table3,$table4], {});
ok $dbh->err;
like $dbh->errstr, qr/join.*\Q$table4\E/;
is $dbh->GetSQL([$table3,$table1,$table2,$table4],{})->{From},
    "`$table3`"
  . " INNER JOIN `$table1` ON (`$table1`.`id_t1` = `$table3`.`id_t1`)"
  . " INNER JOIN `$table2` ON (`$table2`.`id_t2` = `$table3`.`id_t2`)"
  . " INNER JOIN `$table4` ON (`$table4`.`id_t2` = `$table2`.`id_t2`)";
is $dbh->GetSQL($table1,{})->{From}, "`$table1`";

# {Select}
is $dbh->GetSQL($table1,{})->{Select},
    "`$table1`.`id_t1`, `$table1`.`i`",
    '{Select}';
is $dbh->GetSQL([$table1,$table2,$table4],{})->{Select},
    "`$table1`.`id_t1`, `$table1`.`i`, `$table2`.`id_t2`, `$table2`.`s`, `$table4`.`id_t4`";

# {Set}, {Where}, {UpdateWhere}
ok $dbh->GetSQL($table1, {});
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, {
    'i__func'       => 1,           # unknown function
});
like $dbh->errstr, qr/unknown function:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, {
    'i'             => [1],         # ref without function
});
like $dbh->errstr, qr/ARRAYREF without function:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table3, {
    'd__date_eq'    => '2 DAYS',    # bad value for function
});
like $dbh->errstr, qr/bad value/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table3, {
    'd__set_date'   => 'NOW()',     # bad value for function
});
like $dbh->errstr, qr/bad value/;
ok $SQL = $dbh->GetSQL($table1, {
    'i__eq__bad'    => 1,           # ignore bad key
    'some info'     => 1,           # ignore bad key
    'bad__func'     => 1,           # ignore non-field key
});
is $SQL->{Where}, '1';
is $SQL->{UpdateWhere}, '1';
ok $SQL = $dbh->GetSQL($table3, {
    id_t3           => 10,          # PK in {UpdateWhere}
    id_t2           => undef,       # {Set} contain '= NULL' instead of 'IS NULL'
    id_t1__eq       => undef,       # {Where} contain 'IS NULL'
    d__set_date     => 'NOW',       # set_ functions in {Set}
});
is_deeply [sort split /, /, $SQL->{Set}],
    [sort split /, /, "`$table3`.`d` = NOW(), `$table3`.`id_t2` = NULL, `$table3`.`id_t3` = '10'"];
is_deeply [sort split / AND /, $SQL->{Where}],
    [sort split / AND /, "`$table3`.`id_t2` IS NULL AND `$table3`.`id_t1` IS NULL AND `$table3`.`id_t3` = '10'"];
is_deeply [sort split / AND /, $SQL->{UpdateWhere}],
    [sort split / AND /, "`$table3`.`id_t1` IS NULL AND `$table3`.`id_t3` = '10'"];

# {Order}, {Group}
ok $SQL = $dbh->GetSQL($table3, {
    __group     => 'd',                             # scalar
    __order     => ['id_t2', undef, 'id_t3  DESC']  # array, ignore undef
});
is $SQL->{Group}, "`$table3`.`d`";
is $SQL->{Order}, "`$table3`.`id_t2`, `$table3`.`id_t3` DESC";
ok $SQL = $dbh->GetSQL($table3, {
    __group     => ['d ASC'],
    __order     => undef,                           # ignore undef
});
is $SQL->{Group}, "`$table3`.`d` ASC";
is $SQL->{Order}, q{};
ok !$dbh->GetSQL($table3, {
    __order     => 'bad',                           # not a field
});
like $dbh->errstr, qr/bad __order value:/;
ok !$dbh->GetSQL($table3, {
    __group     => 'd ACK',                         # wrong format
});
like $dbh->errstr, qr/bad __group value:/;

# {Limit}, {SelectLimit}
ok $SQL = $dbh->GetSQL($table1, { __limit => undef });
is $SQL->{Limit}, q{};
is $SQL->{SelectLimit}, q{};
ok $SQL = $dbh->GetSQL($table1, { __limit => 0 });
is $SQL->{Limit}, ' 0';
is $SQL->{SelectLimit}, ' 0';
ok $SQL = $dbh->GetSQL($table1, { __limit => [10] });
is $SQL->{Limit}, ' 10';
is $SQL->{SelectLimit}, ' 10';
ok $SQL = $dbh->GetSQL($table1, { __limit => [10,20] });
is $SQL->{Limit}, q{};
is $SQL->{SelectLimit}, '10,20';
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => [undef] });
like $dbh->errstr, qr/bad __limit value:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => q{} });
like $dbh->errstr, qr/bad __limit value:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => [q{}] });
like $dbh->errstr, qr/bad __limit value:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => [10,q{}] });
like $dbh->errstr, qr/bad __limit value:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => [10,-1] });
like $dbh->errstr, qr/bad __limit value:/;
$dbh->set_err(undef,undef);
ok !$dbh->GetSQL($table1, { __limit => [1,2,3] });
like $dbh->errstr, qr/too many __limit values:/;
$dbh->set_err(undef,undef);
ok $SQL = $dbh->GetSQL($table1, { __limit => [] });
is $SQL->{Limit}, q{};
is $SQL->{SelectLimit}, q{};


done_testing;
