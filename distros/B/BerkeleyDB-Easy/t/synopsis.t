use strict;
use warnings;

use Test::More;
use BerkeleyDB::Easy;

my $db = BerkeleyDB::Easy::Btree->new();

is ref $db, 'BerkeleyDB::Easy::Btree';

my $val = $db->put('foo', 'bar');
is $val, 'bar';

my $foo = $db->get('foo');
is $foo, 'bar';

my $cur = $db->cursor;
is ref $cur, 'BerkeleyDB::Easy::Cursor';

while (my ($key, $val) = $cur->next) {
    my $key = $db->del($key);
    is $key, 'foo';
}

done_testing;
