# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Config::Model::Itself ;
use Test::File::Contents ;

use warnings;
use strict;

my ($meta_model, $trace) = init_test();

my $wr_test = setup_test_dir ;
my $wr_model1 = $wr_test->child("wr_model1");
my $wr_plugin = $wr_test->child("wr_plugin.d");

$wr_model1->mkpath;

# copy test model
dircopy('data',$wr_model1->stringify) || die "cannot copy model data:$!" ;
my $plugin_name = 'my_plugin';

# test model plugins, read model in layered mode
my $meta_plugin_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_plugin',
    root_dir        => $wr_model1,
);
ok($meta_plugin_inst,"Read Itself::Model and created instance for model plugin") ;

my $meta_plugin_root = $meta_plugin_inst -> config_root ;

my $plugin_rw_obj = Config::Model::Itself -> new(
    model_object => $meta_plugin_root,
    cm_lib_dir => 'data',
) ;

$meta_plugin_inst->layered_start ;

$plugin_rw_obj -> read_all(
    root_model => 'MasterModel',
) ;

ok(1,"Read all models in data dir in layered mode") ;

$meta_plugin_inst->layered_stop ;

# modify model, X_base_class2 is not a mistake
$meta_plugin_root->load(q!class:MasterModel::X_base_class2 element:X#"X note" help:Cv="Mighty help for Cv"!);
$meta_plugin_root->load(q!class:MasterModel element:a_string warn_if_match:meh msg="said meh"!);

$plugin_rw_obj->write_model_plugin(plugin_dir => $wr_plugin, plugin_name => $plugin_name) ;

my %expected_plugin;
$expected_plugin{MasterModel} = << "EOS" ;
use strict;
use warnings;

return [
  {
    'element' => [
      'a_string',
      {
        'warn_if_match' => {
          'meh' => {
            'msg' => 'said meh'
          }
        }
      }
    ],
    'name' => 'MasterModel'
  }
]
;

EOS

$expected_plugin{"MasterModel/X_base_class2"} = << "EOS" ;
use strict;
use warnings;

return [
  {
    'element' => [
      'X',
      {
        'help' => {
          'Cv' => 'Mighty help for Cv'
        }
      }
    ],
    'name' => 'MasterModel::X_base_class2'
  }
]
;

=head1 Annotations

=over

=item class:"MasterModel::X_base_class2" element:X

X note

=back

EOS

foreach my $name (keys %expected_plugin) {
    file_contents_eq_or_diff(
        $wr_plugin."/$plugin_name/$name.pl", $expected_plugin{$name}, "generated $name plugin file"
    );
}

my $meta_plugin_inst2 = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_plugin',
    root_dir        => $wr_model1,
);
ok($meta_plugin_inst2,"Read Itself::Model and created instance for model plugin") ;

my $meta_plugin_root2 = $meta_plugin_inst2 -> config_root ;

my $plugin_rw_obj2 = Config::Model::Itself -> new(
    cm_lib_dir => 'data',
    model_object => $meta_plugin_root2,
) ;

$meta_plugin_inst2->layered_start ;

$plugin_rw_obj2->read_all(
    root_model => 'MasterModel',
);

ok(1,"Read all models in data dir in layered mode") ;

$meta_plugin_inst->layered_stop ;

$plugin_rw_obj2->read_model_plugin(plugin_dir => $wr_plugin, plugin_name => $plugin_name) ;

my $plugin_name2 = 'other_plugin';
$plugin_rw_obj2->write_model_plugin(plugin_dir => $wr_plugin, plugin_name => $plugin_name2) ;

foreach my $name (keys %expected_plugin) {
    file_contents_eq_or_diff (
        $wr_plugin."/$plugin_name2/$name.pl",  $expected_plugin{$name}, "regenerated $name plugin file"
    );
}

note("testing memory cycles. Please wait...");
memory_cycle_ok($meta_model, "Check memory cycle");

done_testing;
