use Test::More;
use Test::Exception;

use lib './t/lib';

use MySchema;

use strict;
use warnings;

plan tests => 7;

my $schema = MySchema->connect ("dbi:SQLite:dbname=:memory:");

$schema->deploy;

my $tree = $schema->resultset ('Node')->create ({});

$tree->root ($tree);

$tree->update;

ok $tree->is_root,'Root thinks of itself as root';

$tree->children->create ({}) for 1 .. 2;

my $child = $tree->children->create ({});

$child->children->create ({}) for 1 .. 2;

ok ! $child->is_root,'Child does not think of itself as root';

throws_ok { $child->calculate_sets } qr/must be called on tree root/;

$tree->calculate_sets;

$child->discard_changes;

is $tree->lft,1,'Root left is 1';

is $tree->rgt,12,'Root right is 12';

is $child->lft,6,'Child left is 6';

is $child->rgt,11,'Child right is 11';

