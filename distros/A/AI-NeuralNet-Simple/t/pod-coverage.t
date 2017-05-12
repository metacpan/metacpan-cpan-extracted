#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan $@ 
  ? (skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage")
  : ( tests => 1 );

my $ignore = join '|' => qw(
    STORABLE_freeze
    STORABLE_thaw
    build_axaref
    build_rv
    c_destroy_network
    c_export_network
    c_get_delta
    c_get_learn_rate
    c_get_use_bipolar
    c_import_network
    c_infer
    c_load_axa
    c_new_network
    c_set_delta
    c_set_learn_rate
    c_set_use_bipolar
    c_train
    c_train_set
    get_array
    get_array_from_aoa
    get_element
    get_float_element
    handle
    is_array_ref
);

pod_coverage_ok( "AI::NeuralNet::Simple", { trustme => [$ignore] } );

