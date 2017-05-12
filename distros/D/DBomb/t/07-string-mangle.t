use Test::More tests => 15;
use strict;
use warnings;

my $sql_i = 0;

BEGIN {
        use_ok('DBI');
        use_ok('DBomb');
        use_ok('DBomb::Query');
        use_ok('DBomb::Query::Insert');
        use_ok('DBomb::Test::Util',qw(:all));
};

## Connect
my ($dbh,$q);
ok($dbh = $DBomb::Test::Util::dbh
        = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');

drop_table('foo');
ok($dbh->do('CREATE TABLE foo ( foo_id INT NOT NULL, name CHAR(30), PRIMARY KEY (foo_id))'), 'create table foo');

package Foo;
use strict;
use warnings;
use base qw(DBomb::Base);
Foo->def_data_source(undef, 'foo');
Foo->def_column('foo_id', { accessor => 'id' } );
Foo->def_column('name',   { accessor => 'name', string_mangle => 1 } );
Foo->def_primary_key(['foo_id']);


package main;
use strict;
use warnings;
my $foo;

## select_trim
ok(truncate_table('foo'), 'truncate foo');
ok($dbh->do("INSERT INTO foo (foo_id,name) VALUES (1,?)", {}, "  bar  "), "insert '  bar  '");
$foo = new Foo($dbh,1);
ok($foo->name eq 'bar', "select_trim");

## update trim
ok(truncate_table('foo'), 'truncate foo');
ok($dbh->do("INSERT INTO foo (foo_id,name) VALUES (1,?)", {}, "  bar  "), "insert '  bar  '");
$foo = new Foo($dbh,1);
$foo->name('  fum  ');
$foo->update;
my $val = $dbh->selectcol_arrayref("SELECT name FROM foo WHERE foo_id = 1");
ok($val->[0] eq 'fum', "update_trim");
ok($foo->name eq '  fum  ', "update_trim");

ok(drop_table('foo'), 'drop table foo');
1;
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
