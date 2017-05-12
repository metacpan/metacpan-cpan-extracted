#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 14;

package My::Item;
use overload
  '""' => sub { $_[0]->{text} },
  cmp  => sub { "$_[0]" cmp "$_[1]" };

sub new {
    my ($class, %args) = @_;
    bless {%args}, $class;
}

package My::Container;
use base 'Data::Container';

package main;
my $c1 = My::Container->new;
isa_ok($c1, 'Data::Container');
for ('c' .. 'f') {
    $c1->items_push(My::Item->new(text => ($_ x 3)));
}
$c1->items_push('ggg');
is($c1->items_count, 5, "number of items in container");
is("$c1", "ccc\n\nddd\n\neee\n\nfff\n\nggg", "stringified container");
my $c2 = My::Container->new;
$c2->items_push($c1->item_grep('My::Item'));
is($c2->items_count, 4, "number of My::Item items in container");
is("$c2", "ccc\n\nddd\n\neee\n\nfff", "stringified container");

# set_push an item that's already in there: espect no change
$c2->items_set_push(My::Item->new(text => 'ddd'));
is($c2->items_count, 4, "item count unchanged after set_push 'ddd'");
is("$c2", "ccc\n\nddd\n\neee\n\nfff", "stringified container");

# set_push a new item: expect it to be there
$c2->items_set_push(My::Item->new(text => 'kkk'));
is($c2->items_count, 5, "new item count after set_push 'kkk'");
is("$c2", "ccc\n\nddd\n\neee\n\nfff\n\nkkk", "stringified container");

# set_push two items, one that's already there and a new one
$c2->items_set_push(My::Item->new(text => 'kkk'), My::Item->new(text => 'mmm'),
);
is($c2->items_count, 6, "new item count after set_push 'kkk', 'mmm'");
is("$c2", "ccc\n\nddd\n\neee\n\nfff\n\nkkk\n\nmmm", "stringified container");

# set_push the first container onto the second one; expect the plain string to
# be there again.
$c2->items_set_push($c1);
is($c2->items_count, 7, "new item count after set_push of the first container");
is( "$c2",
    "ccc\n\nddd\n\neee\n\nfff\n\nkkk\n\nmmm\n\nggg",
    "stringified container"
);
$c1->items_clear;
is($c1->items_count, 0, 'empty container');
