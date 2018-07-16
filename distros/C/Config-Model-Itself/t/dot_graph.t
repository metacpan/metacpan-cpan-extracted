# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Test::Memory::Cycle;
use Config::Model::Itself ;

use warnings;
use strict;

my ($meta_model, $trace) = init_test();

my $wr_root = setup_test_dir;

my $meta_inst = $meta_model-> instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance',
    root_dir          => "data",
);
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $model_dir = 'lib/Config/Model' ;
my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    cm_lib_dir => $model_dir,
) ;

my $map = $rw_obj -> read_all(
    root_model => 'Itself',
    force_load   => 1,
) ;

ok(1,"Read all models from $model_dir") ;

my $dot_file = $wr_root->child("config-test.dot");

my $res =  $rw_obj->get_dot_diagram ;
ok($res,"got dot data, writting in $dot_file...") ;

print $res if $trace ;

$dot_file->spew_utf8($res);

note("testing memory cycles, please wait...");
memory_cycle_ok($meta_model, "memory cycle");

done_testing;
