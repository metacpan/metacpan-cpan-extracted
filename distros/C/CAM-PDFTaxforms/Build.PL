use Module::Build;

Module::Build->new(
   module_name => 'CAM::PDFTaxforms',
   dist_author => 'Jim Turner. <turnerjw784@yahoo.com>',
   license => 'perl',
   requires => {
      'perl' => '5.6.0',
      'Text::PDF' => '0.29',
      'Crypt::RC4' => '2.02',
      'Digest::MD5' => '2.16',
      'CAM::PDF' => '1.52',
   },
   recommends => {
      # Needed for scripts
      'Getopt::Long' => '2.0',    
      'Pod::Usage' => '1.0',

      # Optional in tests, skipped if not present
      'Test::Pod' => 0,
      'Test::Pod::Coverage' => 0,
      'Test::Memory::Cycle' => '1.02',
   },
   build_requires => {
      'Test::More' => 0,  # needs to be v0.62 for Test::Memory::Cycle v1.02
   },
   script_files => [qw(
      bin/listpdffields2.pl
   )],
   add_to_cleanup => [ 'CAM-PDFTaxforms-*' ],
   create_makefile_pl => 'traditional',
)->create_build_script;
