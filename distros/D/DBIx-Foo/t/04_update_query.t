use Test::More;
use strict;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required';
    eval { DBD::SQLite->VERSION >= 1 }
        or plan skip_all => 'DBD::SQLite >= 1.00 required';

    plan tests => 10;
    use_ok('DBIx::Foo');
}

# In memory database! No file permission troubles, no I/O slowness.
# http://use.perl.org/~tomhukins/journal/31457 ++

my $db = DBIx::Foo->connect('dbi:SQLite:dbname=:memory:');

ok($db);

ok($db->do('CREATE TABLE xyzzy (ID INTEGER PRIMARY KEY, FOO, bar, baz)'));

my $query = $db->update_query('xyzzy');

$query->addField('FOO', 'a');
$query->addField('bar', 'b');
$query->addField('baz', 'c');

is($query->DoInsert, 1, "ID 1 Returned");

my $sql = 'SELECT * FROM xyzzy ORDER BY FOO';

my @row = $db->selectrow_array($sql);

is_deeply(\@row, [ qw(1 a b c) ]);

$query->addFields(FOO => 'd', bar => 'e', baz => 'f');

is($query->DoInsert, 2, "ID 2 Returned");

my $rows = $db->selectall_arrayref($sql);

is_deeply($rows , [[qw(1 a b c)], [qw(2 d e f)]]);

$query->addKey('ID', 2);
$query->addFields(FOO => 'f', bar => 'o', baz => 'o');

ok($query->DoUpdate);

$rows = $db->selectall_arrayref($sql);

is_deeply($rows , [[qw(1 a b c)], [qw(2 f o o)]]);

ok($db->disconnect);
