# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use Path::Tiny;

use Config::Model::Itself ;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Test::Memory::Cycle;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;
$log  = 1 if $arg =~ /l/;
$show = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ( $log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

# do search for the models created in this test
use lib "wr_test/lib";

my $wr_test = path('wr_test') ;
my $wr_conf1 = $wr_test->child("wr_conf1");
my $wr_lib = $wr_test->child("lib");
my $wr_model1 = $wr_lib->child("wr_model1");
my $wr_model2 = $wr_lib->child("wr_model2");

my $meta_model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

$wr_test->remove_tree if $wr_test->is_dir ;

$wr_conf1->mkpath;
$wr_model1->mkpath;
$wr_model2->mkpath;
$wr_conf1->child("etc/ssh")->mkpath;

# copy test model
dircopy('data',$wr_model1->stringify) || die "cannot copy model data:$!" ;

my $model = Config::Model->new(
    legacy => 'ignore',
    model_dir => $wr_model1->child("models")->relative($wr_lib)->stringify
) ;
ok(1,"loaded Master model") ;

# check that Master Model can be loaded by Config::Model
my $inst1 = $model->instance (
    root_class_name   => 'MasterModel',
    instance_name     => 'test_orig',
    root_dir          => $wr_conf1->stringify,
);
ok($inst1,"created master_model instance") ;

my $root1 = $inst1->config_root ;
my @elt1 = $root1->get_element_name ;

$root1->load("a_string=toto lot_of_checklist macro=AD - "
            ."! warped_values macro=C where_is_element=get_element "
            ."                get_element=m_value_element m_value=Cv "
            ."! assert_leaf=foo leaf_with_warn_unless=bar") ;
ok($inst1,"loaded some data in master_model instance") ;

my $dump1 = $root1->dump_tree(mode => 'full') ;
ok($dump1,"dumped master instance") ;

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

my $map = $rw_obj -> read_all(
    root_model => 'MasterModel',
    legacy => 'ignore',
) ;

ok(1,"Read all models in data dir") ;

print $meta_model->list_class_element if $trace ;

my $expected_map 
  = {
     'MasterModel/HashIdOfValues.pl' => [
                             'MasterModel::HashIdOfValues'
                            ],
     'MasterModel/CheckListExamples.pl' => [
                                'MasterModel::CheckListExamples'
                               ],
     'MasterModel.pl' => [
                          'MasterModel::SubSlave2',
                          'MasterModel::SubSlave',
                          'MasterModel::SlaveZ',
                          'MasterModel::SlaveY',
                          'MasterModel::TolerantNode',
                          'MasterModel'
                         ],
     'MasterModel/WarpedId.pl' => [
                       'MasterModel::WarpedIdSlave',
                       'MasterModel::WarpedId'
                      ],
     'MasterModel/X_base_class.pl' => [
                           'MasterModel::X_base_class2',
                           'MasterModel::X_base_class',
                          ],
     'MasterModel/WarpedValues.pl' => [
                           'MasterModel::RSlave',
                           'MasterModel::Slave',
                           'MasterModel::WarpedValues'
                          ],
     'MasterModel/References.pl' => [
                                     'MasterModel::References::Host',
                                     'MasterModel::References::If',
                                     'MasterModel::References::Lan',
                                     'MasterModel::References::Node',
                                     'MasterModel::References'
                                    ],
    };

is_deeply($expected_map, $map, "Check file class map") ;
print Dumper $map if $trace ;

# add a new class 
$meta_root->load("class:Master::Created element:created1 type=leaf value_type=number"
                     ." - element:created2 type=leaf value_type=uniline") ;
ok(1,"added new class Master::Created") ;

my $cds = $meta_root->dump_tree (full_dump => 1) ;
my @cds_orig = split /\n/,$cds ;

print $cds if $trace ;
ok($cds,"dumped full tree in cds format") ;

#like($cds,qr/dumb/,"check for a peculiar warp effet") ;

$wr_conf1->child("orig.cds")->spew($cds);

#create a 2nd empty model
my $meta_inst2 = $meta_model->instance (
    root_class_name   => 'Itself::Model', 
    instance_name     => 'itself_instance'
);

my $meta_root2 = $meta_inst2 -> config_root ;
$meta_root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $meta_root2 ->dump_tree (full_dump => 1) ;
$wr_conf1->child("inst2.cds")->spew($cds2);

is_deeply([split /\n/,$cds2],\@cds_orig,"Compared the 2 full dumps") ; 

my $pdata2 = $meta_root2 -> dump_as_data ;
print Dumper $pdata2 if $trace ;

my $rw_obj2 = Config::Model::Itself -> new(
    model_object => $meta_root2,
    cm_lib_dir => $wr_model2->stringify,
    force_write => 1,
) ;

$rw_obj2 -> write_all();

# create 3rd instance 

my $meta_inst3 = $meta_model->instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance'
);

my $meta_root3 = $meta_inst3 -> config_root ;
$meta_root3 -> load_data ($pdata2) ;
ok(1,"Created and loaded 3nd instance with perl data") ;

my $cds3 = $meta_root3 ->dump_tree (full_dump => 1) ;
$wr_conf1->child("inst3.cds")->spew($cds3);

is_deeply([split /\n/,$cds3],\@cds_orig,"Compared the 3rd full dump with first one") ; 

# check dump of one class
my $dump = $rw_obj -> get_perl_data_model ( class_name => 'MasterModel' ) ;

print Dumper $dump if $trace ;
ok($dump,"Checked dump of one class");

$rw_obj->write_all( ) ;

my $model4 = Config::Model->new(
    legacy => 'ignore',
    model_dir => $wr_model1->child("models")->relative($wr_lib)->stringify
) ;

my $inst4 = $model4->instance (
    root_class_name   => 'MasterModel',
    instance_name     => 'test_instance',
    root_dir  => $wr_conf1->stringify,
);
ok($inst4,"Read MasterModel and created instance") ;

my $root4 = $inst4->config_root ;
ok($root4,"Created MasterModel root") ;

my @elt4 = $root4->get_element_name() ;
is(scalar @elt4,scalar @elt1,"Check number of elements of root4") ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

memory_cycle_ok($model, "Check memory cycle");

done_testing;
