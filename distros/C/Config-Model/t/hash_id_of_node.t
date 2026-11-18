# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;

my ($model, $trace) = init_test();

my @element = (
    # Value constructor args are passed in their specific array ref
    cargo => { type => 'node', config_class_name => 'Slave' },
);

# minimal set up to get things working
$model->create_config_class(
    name    => "Master",
    element => [
        'plain_hash' => {
            type => 'hash',
            class => 'Config::Model::HashId',    # default
            index_type => 'integer',

            @element
        },
        'bounded_hash' => {
            type => 'hash',
            class => 'Config::Model::HashId',    # default
            index_type => 'integer',

            # hash boundaries
            min    => 1,
            max    => 123,
            max_nb => 2,
            @element
        },
    ],
);

$model->create_config_class(
    name    => "Slave",
    element => [
        [qw/X Y Z/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/]
        },
    ] );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $b = $root->fetch_element('bounded_hash');
ok( $b, "bounded hash created" );

is( $b->name, 'Master bounded_hash id', "check hash id name" );

my $b1 = $b->fetch_with_id(1);
isa_ok( $b1, 'Config::Model::Node', "fetched element id 1" );

is( $b1->config_class_name, 'Slave', 'check config_class_name' );

$root->load("plain_hash:2 X=Av Y=Av Z=Cv");
my $ph = $root->fetch_element('plain_hash');
ok( $ph->copy( 2, 3 ), "node copy in hash" );
is( $ph->fetch_with_id(2)->dump_tree, $ph->fetch_with_id(3)->dump_tree, "compare copied values" );

ok( $ph->move( 2, 4 ), "node move in hash" );
is(
    $ph->fetch_with_id(4)->dump_tree,
    $ph->fetch_with_id(3)->dump_tree,
    "compare copied then moved values"
);

is_deeply( [ $ph->fetch_all_indexes ], [ 3, 4 ], "compare indexes after move" );

memory_cycle_ok($model, "memory cycle");
done_testing;
