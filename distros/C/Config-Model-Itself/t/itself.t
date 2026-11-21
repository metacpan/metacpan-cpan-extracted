use ExtUtils::testlib;
use Test::More ;
use Test::Differences;
use Config::Model 2.142;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Data::Dumper ;
use Path::Tiny;

use Config::Model::Itself ;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Test::Memory::Cycle;
use Test::File::Contents;

use warnings;
use strict;
use v5.20;
use utf8;

my ($meta_model, $trace) = init_test();

# do search for the models created in this test
use lib "wr_root/itself/lib";
my @master_model_elts;

my $wr_test = setup_test_dir ;
my $wr_lib = $wr_test->child("lib");
my %write_dirs;

my $wr_conf1 = $wr_test->child("wr_conf1");
$wr_conf1->child("etc/ssh")->mkpath;

subtest "load Master model in Config::Model" => sub {
    # to check that the test model is usable by Config::Model
    my $wr_model = $write_dirs{'master_model'} = $wr_lib->child("wr_master_model");
    $wr_model->mkpath;

    # copy test model
    dircopy('data',$wr_model->stringify) || die "cannot copy model data:$!" ;

    my $model = Config::Model->new(
        model_dir => $wr_model->child("models")->relative($wr_lib)->stringify
    ) ;
    ok(1,"loaded Master model") ;

    # check that Master Model can be loaded by Config::Model
    my $inst = $model->instance (
        root_class_name   => 'MasterModel',
        instance_name     => 'test_orig',
        root_dir          => $wr_conf1->stringify,
    );
    ok($inst,"created master_model instance") ;

    my $root = $inst->config_root ;
    @master_model_elts = $root->get_element_name ;

    $root->load("a_string=toto lot_of_checklist macro=AD - "
                 ."! warped_values macro=C where_is_element=get_element "
                 ."                get_element=m_value_element m_value=Cv "
                 ."! assert_leaf=foo leaf_with_warn_unless=bar") ;
    ok($inst,"loaded some data in master_model instance") ;

    my $dump1 = $root->dump_tree(mode => 'backend') ;
    ok($dump1,"dumped master instance") ;
};

# set by this test and used by following test
my ($cds, @cds_orig);
subtest "load test model in Config::Model::Itself" => sub {
    # ok now we can load test model in Itself
    my $wr_model = $write_dirs{"wr_itself_1"} = $wr_lib->child("wr_itself_1");
    $wr_model->mkpath;

    # copy test model
    dircopy('data',$wr_model->stringify) || die "cannot copy model data:$!" ;

    my $meta_inst = $meta_model -> instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance',
        root_dir          => $wr_model->stringify,
    );
    ok($meta_inst,"Read Itself::Model and created instance") ;

    my $meta_root = $meta_inst -> config_root ;

    my $rw_obj = Config::Model::Itself -> new(
        model_object => $meta_root,
        cm_lib_dir => $wr_model->stringify,
    );

    my $map = $rw_obj->read_all(
        root_model => 'MasterModel',
        legacy => 'warn',
    ) ;

    ok(1,"Read all models in data dir") ;

    print $meta_model->list_class_element if $trace ;

    my $expected_map = {
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
        'MasterModel/ToTrash.pl' => [
            'MasterModel::ToTrash'
        ],
    };

    # check that all expected classes were found in the test files
    is_deeply($expected_map, $map, "Check file class map") ;
    print Dumper $map if $trace ;

    # check that deprecated backend specs are removed
    my $master_model = $meta_inst->grab('class:MasterModel');
    # check => skip prevents deprecation warnings
    is($master_model->grab_value('rw_config backend'), 'cds_file', "read_config data was migrated in rw_config");
    is($master_model->grab_value('rw_config file'), 'mymaster.cds', "write_config data was migrated in rw_config");

    # check that utf8 description is not garbled
    is($master_model->grab_value('element:std_id description'), "test utf8 😀", "test utf8 description");

    # add a new class
    $meta_root->load("class:Master::Created element:created1 type=leaf value_type=number"
                     ." - element:created2 type=leaf value_type=uniline") ;
    ok(1,"added new class Master::Created") ;

    $meta_root->load("class:.rm(MasterModel::ToTrash)");
    ok(1, "removed class ToTrash");

    # data for next test
    $cds = $meta_root->dump_tree () ;
    @cds_orig = split /\n/,$cds ;

    unlike($cds,qr/ToTrash/, "class to trash was removed from model");

    print $cds if $trace ;
    ok($cds,"dumped full tree in cds format") ;

    $wr_conf1->child("orig.cds")->spew_utf8($cds);

    # write back model with the modifications done by Config::Model::Itself model
    $rw_obj -> write_all();
    ok( ! $wr_model->child("models/MasterModel/ToTrash.pl")->exists,
        "trashed model is not written back");

    # check dump of one class
    my $dump = $rw_obj -> get_perl_data_model ('MasterModel') ;

    print Dumper $dump if $trace ;
    ok($dump,"Checked dump of one class");
};

# set by this test and used by following test
my $pdata2;
subtest "load MasterModel in new Itself instance with cds string" => sub {
    my $wr_model2 = $write_dirs{wr_from_cds} = $wr_lib->child("wr_from_cds");
    $wr_model2->mkpath;

    #create a 2nd empty model
    my $meta_inst2 = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance2'
    );

    my $meta_root2 = $meta_inst2 -> config_root ;
    # no check since included classes can be specified before they are
    # loaded.
    $meta_root2 -> load (steps => $cds, check => 'no') ;
    ok(1,"Created and loaded 2nd instance") ;

    my $cds2 = $meta_root2 ->dump_tree () ;
    $wr_conf1->child("inst2.cds")->spew_utf8($cds2);

    eq_or_diff([split /\n/,$cds2],\@cds_orig,"Compared the 2 full cds dumps") ;

    # used in next test
    $pdata2 = $meta_root2 -> dump_as_data ;
    print Dumper $pdata2 if $trace ;

    # write MasterModel as Perl data structure in one big file
    $wr_conf1->child("inst2.pl")->spew_utf8(Dumper $pdata2);

    my $rw_obj2 = Config::Model::Itself -> new(
        model_object => $meta_root2,
        cm_lib_dir => $wr_model2->stringify,
        force_write => 1,
    ) ;

    $rw_obj2 -> write_all();

    my $written_model_file = $wr_model2->child("models/MasterModel.pl");
    file_contents_like  $written_model_file,  qr/use strict;/,  "stricture was added when writing file";
};

subtest "load Itself Perl data" => sub {
    my $meta_inst3 = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance3'
    );

    my $meta_root3 = $meta_inst3 -> config_root ;
    $meta_root3 -> load_data (data => $pdata2, check => 'no') ;
    ok(1,"Created and loaded 3nd instance with perl data") ;

    my $cds3 = $meta_root3 ->dump_tree () ;
    $wr_conf1->child("inst3.cds")->spew_utf8($cds3);

    is_deeply([split /\n/,$cds3],\@cds_orig,"Compared the 3rd full dump with first one") ;
};

subtest "Read MasterModel from saved Perl files" => sub {
    my $wr_model = $write_dirs{"wr_from_perl_files"} = $wr_lib->child("wr_from_perl_files");
    $wr_model->mkpath;

    # copy test model written by "load test model in Config::Model::Itself"
    dircopy($write_dirs{wr_itself_1}->stringify,$wr_model->stringify) || die "cannot copy model data:$!" ;

    my $model4 = Config::Model->new(
        legacy => 'warn',
        model_dir => $wr_model->child("models")->relative($wr_lib)->stringify,
    ) ;

    my $inst4 = $model4->instance (
        root_class_name   => 'MasterModel',
        instance_name     => 'test_instance4',
        root_dir  => $wr_conf1->stringify,
    );
    ok($inst4,"Read MasterModel and created instance from $wr_model") ;

    my $root4 = $inst4->config_root ;
    ok($root4,"Created MasterModel root") ;

    my @elt4 = $root4->get_element_names() ;
    eq_or_diff(\@elt4, \@master_model_elts,"Check number of elements of root4") ;
};

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model, "Check memory cycle");

done_testing;
