use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Brackup::Target::Gmail",
         license     => 'perl',
         requires    => {
                          'Test::More'            => 0,
#                          'Brackup'               => 0,
                          'File::Temp'            => 0,
                          'Net::FS::Gmail'        => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

