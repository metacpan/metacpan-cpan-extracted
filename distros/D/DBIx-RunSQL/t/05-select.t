#!perl -w
use strict;
use Test::More;

use DBIx::RunSQL;

my $can_run = eval {
    require DBD::SQLite;
    1
};

if (not $can_run) {
    plan skip_all => "SQLite not installed";
    exit;
}

plan tests => 10;

my $sql= <<'SQL';
    create table foo (
        name varchar(64)
      , age decimal(4)
    );
    insert into foo (name,age) values ('bar',100);
    insert into foo (name,age) values ('baz',1);
    insert into foo (name,age) values ('Some loong string',1000);
    insert into foo (name,age) values ('No age',null);
SQL

my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => \$sql,
);

my $sth= $test_dbh->prepare(<<'SQL');
    select * from foo;
SQL
$sth->execute;
my $result= DBIx::RunSQL->format_results( sth => $sth );

isnt $result, undef, "We got some kind of result";
like $result, qr/\bname\b.*?\bage\b/m, "Things that look like 'name' and 'age' appear in the string";
like $result, qr/\bbar\b.*?\b100\b/m, "Things that look like 'bar' and '100' appear in the string";

  $sth= $test_dbh->prepare(<<'SQL');
    select * from foo where 1=0;
SQL
$sth->execute;
$result= DBIx::RunSQL->format_results( sth => $sth );

isnt $result, undef, "We got some kind of result";
like $result, qr/\bname\b.*?\bage\b/m, "An empty resultset still outputs the column titles";
unlike $result, qr/\bbar\b.*?\b100\b/m, "(but obviously, no values)";

$sth= $test_dbh->prepare(<<'SQL');
    select * from foo order by name, age;
SQL
$sth->execute;
$result= DBIx::RunSQL->format_results( sth => $sth, rotate => 1 );

isnt $result, undef, "We got some kind of result";
like $result, qr/\bname\b.*?\bbar\s+baz\b/m, "The name row exists";
like $result, qr/\bage\b.*?\b100\b\s+1\b/m, "The age row exists";

$sth= $test_dbh->prepare(<<'SQL');
    select * from foo
    where age is null
SQL
$sth->execute;
$result= DBIx::RunSQL->format_results( sth => $sth, null => '<null>' );
like $result, qr/<null>/m, "We can set custom strings for NULL";
