use Test::More tests => 11;
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

## Create table FOO;
drop_table('foo');
ok($dbh->do('CREATE TABLE foo ( foo_id INT NOT NULL, bar INT, PRIMARY KEY (foo_id))'), 'create table foo');

package Foo;
use strict;
use warnings;
use base qw(DBomb::Base);
Foo->def_data_source(undef, 'foo');
Foo->def_column('foo_id', { accessor => 'id' } );
Foo->def_accessor('bar',  { expr => '(bar * 2 )' });
Foo->def_primary_key(['foo_id']);


package main;
use strict;
use warnings;
my $foo;

## select_trim
ok(truncate_table('foo'), 'truncate foo');
ok($dbh->do("INSERT INTO foo (foo_id,bar) VALUES (1,?)", {}, 8), "insert 8");
$foo = new Foo($dbh,1);
$foo->bar;
ok($foo->bar eq '16', "select expr");

ok(drop_table('foo'), 'drop the table');

1;
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
