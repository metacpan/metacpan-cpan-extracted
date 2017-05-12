#!perl

use 5.010;
use strict;
use warnings;

use Data::Random::Tree qw(create_random_tree);
use Test::More 0.98;
use Tree::Object::Hash;

# sanity test

my $i = 0;
my $depth = 0;

my $tree = create_random_tree(
    num_objects_per_level => [100, 3000, 5000, 8000, 3000, 1000, 300],
    classes => ['Tree::Object::Hash'],
    code_instantiate_node => sub {
        my ($class, $level, $parent) = @_;
        $depth = $level if $depth < $level;
        $class->new(id => $i++);
    },
);

is($i, 20401, "number of objects created");
is($depth, 7, "depth");
done_testing;
