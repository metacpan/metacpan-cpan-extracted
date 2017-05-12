use strict;
use warnings;
use utf8;
use Test::More;

use DBIx::Simple::UTF8Columns;

eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite is required';
eval { DBD::SQLite->VERSION >= 1 }
    or plan skip_all => 'DBD::SQLite >= 1.00 is required';
eval { require DBIx::Simple::OO; 1 }
    or plan skip_all => 'DBIx::Simple::OO is required';

#plan 'no_plan';
plan tests => 17;

my $db = DBIx::Simple::UTF8Columns->connect(
	'dbi:SQLite:dbname=:memory:',
	'', '',
	{
		RaiseError => 1,
	}
);
ok($db);

my $test_values = [qw( 漢字 ☺ １２３ )];

ok($db->query('CREATE TABLE xyzzy (FOO, bar, baz)'));

ok($db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (??)', qw( 漢字 ☺ １２３ )));
ok($db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (??)', qw( かな ☻ ４５６ )));

my $item = $db->query('SELECT * FROM xyzzy WHERE bar = ?', '☻')->object;
isa_ok($item, 'DBIx::Simple::OO::Item');
is($item->foo, 'かな');
is($item->bar, '☻');
is($item->baz, '４５６');

my @items = $db->query('SELECT * FROM xyzzy ORDER BY baz')->objects;
is($#items, 1);
isa_ok($items[0], 'DBIx::Simple::OO::Item');
isa_ok($items[1], 'DBIx::Simple::OO::Item');
is($items[0]->foo, '漢字');
is($items[0]->bar, '☺');
is($items[0]->baz, '１２３');
is($items[1]->foo, 'かな');
is($items[1]->bar, '☻');
is($items[1]->baz, '４５６');

# avoid warnings
$db->lc_columns;
