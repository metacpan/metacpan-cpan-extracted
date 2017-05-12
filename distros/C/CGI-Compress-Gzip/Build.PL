use Module::Build;
Module::Build->new(
   module_name => 'CGI::Compress::Gzip',
   dist_author => 'Chris Dolan <cdolan@cpan.org>',
   license => 'perl',
   requires => {
      'perl'             => '5.006',
      'CGI'              => '2.00',
      'IO::Zlib'         => '1.01',
      'Compress::Zlib'   => 2,  # Need v2 for coming fileno support
   },
   build_requires => {
      'Test::More'       => '0.01',
      'File::Temp'       => 0,
   },
   add_to_cleanup => [ 'CGI-Compress-Gzip-*' ],
   create_readme => 1,
   create_makefile_pl => 'traditional',
)->create_build_script;
