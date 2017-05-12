use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name        => "CPU::Emulator::DCPU16",
         license            => 'perl',
         script_files       => [ 'bin/dcpu16' ],
         configure_requires => { 
                                'Module::Build'   => 0.38 
                               },
         requires           => {
                                'Test::More'      => 0,
                               },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

