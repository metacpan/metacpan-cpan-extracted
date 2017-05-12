use strict;
use warnings;
use Test::More;
use t::SimpleEntity;

{
    my $entity = t::SimpleEntity->new(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );
    is $entity->key2->[1], 'y';
    ok $entity->is_dirty;

    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';
    is $entity->key1->{nested}->{count}, 1;
    ok $entity->is_dirty;

    $entity->revert;
    is $entity->key1, undef;
    is $entity->key2, undef;
    ok ! $entity->is_dirty, 'No data to store';
}

{
    my $entity = t::SimpleEntity->from_hash(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );
    is $entity->key2->[1], 'y';
    ok ! $entity->is_dirty;

    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';
    is $entity->key1->{nested}->{count}, 1;
    ok $entity->is_dirty;

    $entity->revert;
    is $entity->key1->{nested}->{count}, 0;
    is_deeply $entity->key2, ['x', 'y'];
    ok ! $entity->is_dirty;
}

{
    my $entity = t::SimpleEntity->from_hash(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );

    # Change values
    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';

    # Revert by myself
    $entity->key1({nested => {count => 0}});
    pop @{$entity->key2};
    is $entity->key1->{nested}->{count}, 0;
    is_deeply $entity->key2, ['x', 'y'];
    ok ! $entity->is_dirty;
}

done_testing;
