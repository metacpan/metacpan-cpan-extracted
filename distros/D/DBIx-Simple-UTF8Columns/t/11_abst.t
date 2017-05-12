use strict;
use warnings;
use utf8;
use Test::More;

use DBIx::Simple::UTF8Columns;

eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite is required';
eval { DBD::SQLite->VERSION >= 1 }
    or plan skip_all => 'DBD::SQLite >= 1.00 is required';
eval { require SQL::Abstract; 1 }
    or plan skip_all => 'SQL::Abstract is required';

#plan 'no_plan';
plan tests => 8;

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

ok($db->insert('xyzzy', { FOO => '漢字', bar => '☺', baz => '１２３' }));
ok($db->insert('xyzzy', { FOO => 'かな', bar => '☻', baz => '４５６' }));

is_deeply($db->select('xyzzy', [qw( FOO baz )], { bar => '☻' })->hash, { foo => 'かな', baz => '４５６' });

ok($db->update('xyzzy', { FOO => '〒▼' }, { baz => '１２３' }));
ok($db->delete('xyzzy', { baz => '４５６' }));

is_deeply(scalar $db->select('xyzzy', '*')->hashes, [{ foo => '〒▼', bar => '☺', baz => '１２３' }]);

# avoid warnings
$db->lc_columns;
