use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use Data::TreeValidator::Sugar qw( branch leaf repeating );
use aliased 'Data::TreeValidator::Branch';
use aliased 'Data::TreeValidator::Leaf';
use aliased 'Data::TreeValidator::RepeatingBranch';

test 'branch with no chidren' => sub {
    my $branch = branch {};

    isa_ok($branch, 'Data::TreeValidator::Branch',
        'branch {} creates a branch');
    is($branch->children, 0,
        'branch {} has no children');
};

test 'branch with children' => sub {
    my $branch = branch {
        first_name => leaf,
        last_name => leaf,
        details => branch {},
    };

    isa_ok($branch => Branch,
        'branch { ... } creates a branch');

    is($branch->children => 3,
        'branch { ... } has children');
    ok(defined $branch->child('first_name'), 'has the "first_name" child');
    ok(defined $branch->child('last_name'), 'has the "last_name" child');
    ok(defined $branch->child('details'), 'has the "details" branch');
    ok(!defined $branch->child('missing'), 'does not have the "missing" child');
};

test 'simple leaf' => sub {
    my $leaf = leaf;

    isa_ok($leaf, Leaf, 'leaf() creates a leaf');
    is($leaf->constraints, 0, 'leaf has no constraints');
    is($leaf->transformations, 0, 'leaf has no transformations');
};

test 'leaf with constraints' => sub {
    my $constraint = sub { };
    my $leaf = leaf( constraints => [ $constraint ] );

    isa_ok($leaf => Leaf, 'leaf() creates a leaf');
    is($leaf->constraints => 1, 'leaf has 1 constraint');
    is(($leaf->constraints)[0] => $constraint, 'leaf has the constraint');
    is($leaf->transformations, 0, 'leaf has no transformations');
};

test 'leaf with transformations' => sub {
    local $TODO = "Sugar for transformations";
    fail('Not yet implemented');
};

test 'repeating branches' => sub {
    my $branch = repeating {};

    isa_ok($branch => RepeatingBranch,
        'repeating {} creates a repeating branch');

    is($branch->children => 0, 'branch has no children');
};

run_me;
done_testing;
