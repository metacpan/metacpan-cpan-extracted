use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Convert::MIL1750A",
         license      => 'perl',
         script_files => [ ],
         requires     => {
                          'Bit::Vector'    => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

