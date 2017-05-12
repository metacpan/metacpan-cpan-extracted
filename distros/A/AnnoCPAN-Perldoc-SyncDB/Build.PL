use Module::Build;
Module::Build->new(
   module_name => 'AnnoCPAN::Perldoc::SyncDB',
   license => 'perl',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   reccomends => {
      'AnnoCPAN::Perldoc' => '0.10',
      'Compress::Zlib' => 0,
      'Compress::Bzip2' => 0,
   },
   requires => {
      'LWP::UserAgent' => 0,
      'File::Spec' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   script_files => ['script/syncannopod'],
   add_to_cleanup => [ 'AnnoCPAN-Perldoc-SyncDB-*' ],
)->create_build_script;
