# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Differences ;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Config::Model::Itself ;

use warnings;
use strict;

my ($meta_model, $trace) = init_test();

my $wr_test = setup_test_dir ;
my $wr_model1 = $wr_test->child("wr_model1");

my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_instance',
    root_dir => $wr_model1,
);
ok( $meta_inst, "Read Itself::Model and created instance" );
$meta_inst->initial_load_stop ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    cm_lib_dir => $wr_model1,
    force_write => 1, # can put 0 when Config::MOdel 1.214 is used
) ;

# add a new class 
my @list = (1..3);
foreach my $i (@list) {
    $meta_root->load(
    qq/class:Master::Created$i#"my great class $i"
        class_description="Master class created nb $i\nfor tests purpose." 
        author="dod\@foo.com" copyright="2011 dod" license="LGPL"
       element:created1 type=leaf#"not autumn" value_type=number description="element 1" - 
    element:created2 type=leaf value_type=uniline description="another element"/) ;
}
ok(1,"added new class Master::Created") ;

$rw_obj->write_all(  ) ;
ok(1,"wrote back all stuff") ;

my $meta_inst2 = $meta_model -> instance (
    root_class_name   => 'Itself::Model', 
    instance_name     => 'itself_instance2',
    root_dir          => $wr_model1,
) ;
my $meta_root2 = $meta_inst2->config_root ;
$meta_inst2->initial_load_stop ;

ok($meta_root2,"Read Itself::Model and created instance2") ;
my $rw_obj2 = Config::Model::Itself -> new(
    cm_lib_dir => $wr_model1 ,
    model_object => $meta_root2
) ;
$rw_obj2->read_all(  root_model => 'Master' ) ;

eq_or_diff($meta_root2->dump_tree, $meta_root->dump_tree,"compare 2 dumps");

done_testing;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

