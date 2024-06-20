use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Data::Checks',
   requires => {
      perl => '5.022', # op_convert_list()
   },
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      dist => [ 'share' ],
   },
   extra_compiler_flags => [qw( -Ishare/include -Ihax )],
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
