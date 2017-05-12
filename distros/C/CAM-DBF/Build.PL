use Module::Build;
Module::Build->new(
   module_name => 'CAM::DBF',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'Getopt::Long' => '2.0',
      'Pod::Usage'   => '1.0',
   },
   build_requires => {
      'Test::More'  => 0,
      'Time::HiRes' => 0,
      'File::Temp'  => 0,
   },
   script_files => [
      'bin/dbf2csv',
      'bin/packdbf',
      'bin/debugdbf',
   ],
   add_to_cleanup => [ 'CAM-DBF-*' ],
   create_makefile_pl => 'traditional',
)->create_build_script;
