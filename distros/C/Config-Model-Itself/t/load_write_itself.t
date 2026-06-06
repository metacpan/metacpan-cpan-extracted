use ExtUtils::testlib;
use Test::More;
use Test::Differences;
use Config::Model 2.138;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Data::Dumper ;
use Config::Model::Itself ;
use Text::Diff;
use Path::Tiny;
use File::Copy::Recursive qw(fcopy rcopy dircopy);

use warnings;
use strict;
use 5.10.1;

$File::Copy::Recursive::KeepMode = 0;

my ($meta_model, $trace) = init_test();

my $wr_test = setup_test_dir ;

# copy itself model
# avoid patching this file for Debian autopkgtest
my $orig_cm_dir = path($INC{'Config/Model/Itself.pm'})->parent;
my $orig_model_dir = $orig_cm_dir->child('models');
my $target_cm_dir = $wr_test->child('lib/Config/Model');
my $target_model_dir = $target_cm_dir->child('models');
note("Copying models from $orig_model_dir");

# start copy *below* models.
# See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=809294
dircopy($orig_cm_dir->stringify, $target_cm_dir->stringify);

my @expected_classes =
    qw/
          Itself::Application Itself::CargoElement
          Itself::Class Itself::CommonElement
          Itself::CommonElement::Assert
          Itself::CommonElement::Update
          Itself::CommonElement::UpdateFiles
          Itself::CommonElement::WarnIfMatch Itself::ComputedValue
          Itself::ConfigAccept Itself::ConfigReadWrite
          Itself::ConfigReadWrite::DefaultLayer Itself::Element
          Itself::MigratedValue Itself::Model Itself::NonWarpableElement
          Itself::WarpApply Itself::WarpOnlyElement Itself::WarpValue
          Itself::WarpableElement
      /;

my $ref_cds;
my @ref_elements;
subtest "Dog food Itself" => sub {
    my $inst = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance',
        root_dir          => $wr_test,
    );
    ok($inst,"Read Itself::Model and created instance") ;

    my $root = $inst -> config_root ;

    my $rw_obj    = Config::Model::Itself->new(
        cm_lib_dir  => $target_cm_dir->stringify,
        model_object => $root
    );

    # filter out applications not related to "Itself" model.  when using
    # "system" libraries
    my $map = $rw_obj->read_all( root_model => 'Itself', application => 'itself' );

    ok(1,"Read all models from $target_model_dir") ;

    my @classes = $root->fetch_element('class')->fetch_all_indexes;
    is_deeply(\@classes, \@expected_classes, "found all configuration classes of Itself model");

    # TODO: check order of these elments after write_all, need to load written data
    @ref_elements = $root->grab('class:"Itself::NonWarpableElement" element')->fetch_all_indexes;

    my @apps = $root->fetch_element('application')->fetch_all_indexes;
    is_deeply(\@apps, [], "found no applications as they are filtered out");

    $ref_cds = $root->dump_tree (mode => 'custom') ;

    print $ref_cds if $trace ;
    ok($ref_cds,"dumped full tree in cds format") ;

    $rw_obj->write_all();
    ok (1,"wrote back model") ;
};

my $ref_pdata;
subtest "load model with cds data" => sub {
    #create a 2nd empty model
    my $inst = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance2'
    );

    my $root = $inst -> config_root ;
    # need to pre-load classes, otherwise loading warp fails on
    # unknown classes
    foreach my $class (@expected_classes) {
        $root->fetch_element('class')->fetch_with_id($class);
    }

    $root-> load ($ref_cds) ;
    ok(1,"Created and loaded instance with cds data") ;

    my $cds = $root ->dump_tree (mode => 'custom') ;
    print $cds if $trace ;

    is(my_diff(\$ref_cds,\$cds),'',"Compared the 2 full dumps") ;

    $ref_pdata = $root -> dump_as_data(mode => 'custom') ;
    print Dumper $ref_pdata if $trace ;
};

# create 3rd instance - test load after dump_as_data
subtest "load model with Perl data" => sub {
    my $inst = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance3'
    );

    my $root = $inst -> config_root ;
    # need to pre-load classes, otherwise loading warp fails on
    # unknown classes
    foreach my $class (@expected_classes) {
        $root->fetch_element('class')->fetch_with_id($class);
    }

    $root -> load_data ($ref_pdata) ;
    ok(1,"Created and loaded instance with perl data") ;

    my $cds = $root ->dump_tree (mode => 'custom') ;

    is( my_diff(\$ref_cds, \$cds),'',"Compared the full dump with first one");
};

subtest "load the model that was written back" => sub {
    my $inst = $meta_model->instance (
        root_class_name   => 'Itself::Model',
        instance_name     => 'itself_instance4'
    );

    my $root = $inst -> config_root ;

    my $rw_obj = Config::Model::Itself->new(
        cm_lib_dir  => $target_cm_dir->stringify,
        model_object => $root
    );

    # filter out applications not related to "Itself" model.  when using
    # "system" libraries
    my $map = $rw_obj->read_all( root_model => 'Itself', application => 'itself' );

    ok(1,"Created and loaded  instance with written back model") ;

    my $cds = $root->dump_tree(mode => 'custom');

    is( my_diff(\$ref_cds, \$cds),'',"Compared the full dump with the first one");

    my @elements = $root->grab('class:"Itself::NonWarpableElement" element')->fetch_all_indexes;

    eq_or_diff(\@elements, \@ref_elements, "check element list of a class");
};

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

done_testing;

sub my_diff {
    return diff( @_ , { STYLE => "Unified" } );
}
