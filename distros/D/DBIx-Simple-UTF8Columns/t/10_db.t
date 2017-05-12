use strict;
use warnings;
use utf8;
use Test::More;

use DBIx::Simple::UTF8Columns;

eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite is required';
eval { DBD::SQLite->VERSION >= 1 }
    or plan skip_all => 'DBD::SQLite >= 1.00 is required';

#plan 'no_plan';
plan tests => 12;

my $db = DBIx::Simple::UTF8Columns->connect(
	'dbi:SQLite:dbname=:memory:',
	'', '',
	{
		RaiseError => 0,
	}
);
ok($db);

my $test_values = [qw( 漢字 ☺ １２３ )];

ok($db->query('CREATE TABLE xyzzy (FOO, bar, baz)'));

ok($db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (?, ?, ?)', @$test_values));

is_deeply([ $db->query('SELECT * FROM xyzzy')->flat ], $test_values);

is_deeply([ $db->query('SELECT * FROM xyzzy')->list ], $test_values);

is_deeply(  $db->query('SELECT * FROM xyzzy')->array , $test_values);

ok($db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (?, ?, ?)', qw( かな ☻ ４５６ )));

is_deeply(scalar $db->query('SELECT * FROM xyzzy')->hashes, [ { foo => '漢字', bar => '☺', baz => '１２３' }, { foo => 'かな', bar => '☻', baz => '４５６' } ]);

is_deeply($db->query('SELECT bar FROM xyzzy WHERE baz = ?', '１２３')->hash, { bar => '☺' });

# test when error occurs
ok($db->begin());
ok($db->query('INSERT INTO xyzzy (FXX) VALUES (??)', 'dummy') || 1);
ok($db->rollback());

# avoid warnings
$db->lc_columns;
