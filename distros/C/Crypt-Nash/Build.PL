use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Crypt::Nash",
         license      => 'perl',
         configure_requires => { 'Module::Build' => 0.38 },
         requires     => {
                          'Test::More'                   => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

