use v5;
use strict;
use warnings;

use lib 'inc';
use Module::Build::with::XSTests;

my $build = Module::Build::with::XSTests->new(
   module_name => 'Data::Checks',
   requires => {
      perl => '5.022', # op_convert_list()

      ( $^V lt v5.38 ) ? (
         'builtin::Backport' => 0,
      ) : (),
   },
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      module => { "Data::Checks" => [ 'share' ] },
   },
   extra_compiler_flags => [qw( -Ishare/include -Iinclude -Ihax )],
   c_source => [ "src/" ],
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
