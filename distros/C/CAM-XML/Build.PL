use Module::Build;
Module::Build->new(
   module_name => 'CAM::XML',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'perl'                     => '5.006',
      'XML::Parser'              => '2.27',
   },
   build_requires => {
      'Test::More'               => '0.01',
   },
   add_to_cleanup => [ 'CAM-XML-*' ],
)->create_build_script;
