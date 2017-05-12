use strict;
use Test::More tests => 5;

use Class::DBI::SQLite;
use DBI;

unlink './t/table.db' if -e './t/table.db';

my $dbh = DBI->connect(
    'dbi:SQLite:dbname=./t/table.db', '', '',
    {
	RaiseError => 1,
	PrintError => 1,
	AutoCommit => 1
    }
);

$dbh->do('CREATE TABLE foo (id INTEGER NOT NULL PRIMARY KEY, foo INTEGER, bar TEXT)');

package Foo;
use base qw(Class::DBI::SQLite);

__PACKAGE__->set_db(Main => 'dbi:SQLite:dbname=./t/table.db', '', '');
__PACKAGE__->set_up_table('foo');

package main;

is(Foo->table, 'foo');
is(Foo->columns, 3);
my @columns = sort Foo->columns('All');
is_deeply(\@columns, [sort qw(id foo bar)]);

for my $i(1 .. 10) {
    Foo->create({
	foo => $i,
	bar => 'bar'. $i
    });
}

my $obj = Foo->retrieve(3);
is($obj->bar, 'bar3');

my $new_obj = Foo->create({
    foo => 100,
    bar => 'barbar'
});
is($new_obj->id, 11);

END {
    unlink './t/table.db';
}
