use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Cal::DAV",
         license     => 'perl',
         requires    => {
                          'Test::More'     => '0.62',
                          'Data::ICal'     => '0.12',
                          'HTTP::DAV'      => '0.31',
                          'LWP'            => '5.808',
                        },
         scripts     => [],
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

