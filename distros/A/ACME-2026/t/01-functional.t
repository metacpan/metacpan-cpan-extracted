#!perl
use 5.008003;
use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use ACME::2026 qw(:all);

my $plan = plan_new(title => '2026');
is($plan->{title}, '2026', 'plan title');
is(ref $plan->{items}, 'ARRAY', 'plan items array');

my $id1 = add_item($plan, 'Run a marathon',
    list => 'Health',
    tags => ['fitness'],
    priority => 2,
    due => '2026-10-01',
);
my $id2 = add_item($plan, 'Publish a book', list => 'Work', tags => ['writing']);

is($id1, 1, 'first id');
is($id2, 2, 'second id');

my $item = get_item($plan, $id1);
is($item->{status}, 'todo', 'default status');
is($item->{list}, 'Health', 'list stored');

complete_item($plan, $id1, note => 'Signed up');
$item = get_item($plan, $id1);
is($item->{status}, 'done', 'completed');
is(scalar @{ $item->{notes} }, 1, 'note added');

my @todo = items($plan, status => 'todo');
is(scalar @todo, 1, 'todo filter');

my $stats = stats($plan);
is($stats->{total}, 2, 'stats total');
is($stats->{done}, 1, 'stats done');
is($stats->{complete_pct}, 50, 'stats percent');

my ($fh, $path) = tempfile();
close $fh;
plan_save($plan, $path);

my $loaded = plan_load($path);
is($loaded->{title}, '2026', 'loaded title');
is(scalar @{ $loaded->{items} }, 2, 'loaded items');
is(scalar items($loaded, status => 'done'), 1, 'loaded status filter');

done_testing;
