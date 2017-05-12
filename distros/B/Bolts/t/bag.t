#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;
use Bolts;

my $empty_meta = Bolts::Bag->start_bag(
    package => 'Test::Bolts::Empty',
);

is($empty_meta->name, 'Test::Bolts::Empty');
ok(!$empty_meta->is_finished_bag, 'not finished yet');

$empty_meta->finish_bag;

ok($empty_meta->is_finished_bag, 'now finished');

my $empty = $empty_meta->name->new;

isa_ok($empty, 'Test::Bolts::Empty');

my $empty_again_meta = Bolts::Bag->start_bag(
    package => 'Test::Bolts::Empty',
);

ok($empty_meta->is_finished_bag, 'already finished');

my $meta = Bolts::Bag->start_bag(
    package => 'Test::Bolts::Regular',
);

$meta->add_artifact(value_1 => 42);
$meta->add_artifact(value_2 => sub { 43 });
$meta->add_artifact(value_3 => Bolts::Artifact->new(
    name         => 'value_3',
    scope        => $meta->locator->acquire('scope', 'singleton'),
    blueprint    => $meta->locator->acquire('blueprint', 'acquired', {
        path => [ '__value_3' ],
    }),
));
$meta->add_attribute(__value_3 => (
    is          => 'ro',
    init_arg    => 'value_3',
));

$meta->finish_bag;

my $bag = $meta->name->new( value_3 => 44 );

is($bag->acquire('value_1'), 42);
is($bag->acquire('value_2'), 43);
is($bag->acquire('value_3'), 44);

my $bag2= $meta->name->new( value_3 => 97 );

is($bag2->acquire('value_1'), 42);
is($bag2->acquire('value_2'), 43);
is($bag2->acquire('value_3'), 97);

