# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Path::Tiny;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Config::Model::Itself ;

use warnings;
use strict;

my ($meta_model, $trace) = init_test();

my $meta_inst = $meta_model -> instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance',
    root_dir          => "data",
);
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $model_dir = path($INC{'Config/Model/Itself.pm'})->parent;
note("Reading models from $model_dir");

my $rw_obj    = Config::Model::Itself->new(
    cm_lib_dir   => $model_dir,
    model_object => $meta_root
);

my $map = $rw_obj->read_all(
    root_model => 'Itself',
    force_load => 1,
);

ok(1,"Read all models from $model_dir") ;

my $list =  $rw_obj->list_class_element;
ok($list,"got structure") ;

print $list if $trace ;

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model, "Check memory cycle");

done_testing;
