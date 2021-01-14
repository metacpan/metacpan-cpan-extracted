# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model 2.138;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;

use Config::Model::Itself ;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Test::Memory::Cycle;

use 5.10.1;
use warnings;
use strict;

my ($meta_model, $trace) = init_test();

# do search for the models created in this test
use lib "wr_root/itself/lib";

my $wr_test = setup_test_dir ;
my $wr_lib = $wr_test->child("lib");
my $wr_model1 = $wr_lib->child("wr_model1");

$wr_model1->mkpath;

# copy test model
dircopy('data',$wr_model1->stringify) || die "cannot copy model data:$!" ;

my $model = Config::Model->new(
    model_dir => $wr_model1->child("models")->relative($wr_lib)->stringify
) ;
ok(1,"loaded Master model") ;

# ok now we can load test model in Itself

my $meta_inst = $meta_model -> instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance',
    root_dir          => $wr_model1->stringify,
);
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    cm_lib_dir => $wr_model1->stringify,
) ;

ok($rw_obj,"Created model reader/writer");

$rw_obj->read_all(
    root_model => 'MasterModel',
    legacy => 'ignore',
) ;

ok(1,"Read all models in data dir") ;

is_deeply(
    [ $meta_root->grab('application')->fetch_all_indexes ],
    [ qw/goner master/],
    "check that 2 application files were read"
);

# remove dummy application
$meta_root->load("application:.rm(goner)");

is_deeply(
    [ $meta_root->grab('application')->fetch_all_indexes ],
    [ qw/master/],
    "check that 1 application is left"
);

$rw_obj -> write_all();
ok(1,"Wrote back model") ;

ok(
    ! $wr_model1->child('application.d/goner')->exists,
    "check that goner application file was removed"
);

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model, "Check memory cycle");

done_testing;
