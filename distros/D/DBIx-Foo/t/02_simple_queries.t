use Test::More;
use strict;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required';
    eval { DBD::SQLite->VERSION >= 1 }
        or plan skip_all => 'DBD::SQLite >= 1.00 required';

    plan tests => 9;
    use_ok('DBIx::Foo');
}

# In memory database! No file permission troubles, no I/O slowness.
# http://use.perl.org/~tomhukins/journal/31457 ++

my $db = DBIx::Foo->connect('dbi:SQLite:dbname=:memory:');

ok($db);

my $result = eval { $db->do('SYNTAX ERR0R !@#!@#'); };

is($result, undef, "Query Failed");

ok($db->do('CREATE TABLE xyzzy (FOO, bar, baz)'));

ok($db->do('INSERT INTO xyzzy (FOO, bar, baz) VALUES (?, ?, ?)', 'a', 'b', 'c'));

my $sql = 'SELECT * FROM xyzzy ORDER BY FOO';

my @row = $db->selectrow_array($sql);

is_deeply(\@row, [ qw(a b c) ]);

ok($db->do('INSERT INTO xyzzy VALUES (?, ?, ?)', qw(d e f)));

my $rows = $db->selectall_arrayref($sql);

is_deeply($rows , [[qw(a b c)], [qw( d e f)]]);


ok($db->disconnect);
