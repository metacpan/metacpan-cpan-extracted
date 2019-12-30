# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;
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

my $inst = $meta_model->instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance',
    root_dir          => $wr_test,
);
ok($inst,"Read Itself::Model and created instance") ;

my $root = $inst -> config_root ;

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

my $rw_obj    = Config::Model::Itself->new(
    cm_lib_dir  => $target_cm_dir->stringify,
    model_object => $root
);

# filter out applications not related to "Itself" model.  when using
# "system" libraries
my $map = $rw_obj->read_all( root_model => 'Itself', application => 'itself' );

ok(1,"Read all models from $target_model_dir") ;

my @expected_classes = qw/Itself::Application Itself::CargoElement
Itself::Class Itself::CommonElement Itself::CommonElement::Assert
Itself::CommonElement::WarnIfMatch Itself::ComputedValue
Itself::ConfigAccept Itself::ConfigReadWrite
Itself::ConfigReadWrite::DefaultLayer Itself::Element
Itself::MigratedValue Itself::Model Itself::NonWarpableElement
Itself::WarpOnlyElement Itself::WarpValue Itself::WarpableCargoElement
Itself::WarpableElement/;

my @classes = $root->fetch_element('class')->fetch_all_indexes;
is_deeply(\@classes, \@expected_classes, "found all configuration classes of Itself model");


my @apps = $root->fetch_element('application')->fetch_all_indexes;
is_deeply(\@apps, [], "found no applications as they are filtered out");

my $cds = $root->dump_tree (mode => 'backend') ;

print $cds if $trace ;
ok($cds,"dumped full tree in cds format") ;

#create a 2nd empty model
my $inst2 = $meta_model->instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance2'
);

my $root2 = $inst2 -> config_root ;
foreach my $class (@expected_classes) {
    $root2->fetch_element('class')->fetch_with_id($class);
}
$root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $root2 ->dump_tree (mode => 'backend') ;
print $cds2 if $trace ;

is(my_diff(\$cds,\$cds2),'',"Compared the 2 full dumps") ;

my $pdata2 = $root2 -> dump_as_data ;
print Dumper $pdata2 if $trace ;

# create 3rd instance

my $inst3 = $meta_model->instance (
    root_class_name   => 'Itself::Model',
    instance_name     => 'itself_instance3'
);

my $root3 = $inst -> config_root ;
foreach my $class (@expected_classes) {
    $root3->fetch_element('class')->fetch_with_id($class);
}
$root3 -> load_data ($pdata2) ;
ok(1,"Created and loaded 3nd instance with perl data") ;

my $cds3 = $root3 ->dump_tree (mode => 'backend') ;

is( my_diff(\$cds, \$cds3),'',"Compared the 3rd full dump with first one") ; 

$rw_obj->write_all() ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

done_testing;

sub my_diff {
    return diff( @_ , { STYLE => "Unified" } );
}
