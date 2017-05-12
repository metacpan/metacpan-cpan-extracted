use Module::Build;

Module::Build->new(
   module_name => 'CAM::PDF',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'perl' => '5.6.0',
      'Text::PDF' => '0.29',
      'Crypt::RC4' => '2.02',
      'Digest::MD5' => '2.16',
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
      bin/appendpdf.pl
      bin/asciify
      bin/changepagestring.pl
      bin/changepdfstring.pl
      bin/changerefkeys.pl
      bin/crunchjpg_tmpl.pdf
      bin/crunchjpgs.pl
      bin/deillustrate.pl
      bin/deletepdfpage.pl
      bin/extractallimages.pl
      bin/extractjpgs.pl
      bin/fillpdffields.pl
      bin/getpdffontobject.pl
      bin/getpdfpage.pl
      bin/getpdfpageobject.pl
      bin/getpdftext.pl
      bin/listfonts.pl
      bin/listimages.pl
      bin/listpdffields.pl
      bin/pdfinfo.pl
      bin/readpdf.pl
      bin/renderpdf.pl
      bin/replacepdfobj.pl
      bin/revertpdf.pl
      bin/rewritepdf.pl
      bin/setpdfbackground.pl
      bin/setpdfpage.pl
      bin/stamppdf.pl
      bin/uninlinepdfimages.pl
   )],
   add_to_cleanup => [ 'CAM-PDF-*' ],
   create_makefile_pl => 'traditional',
)->create_build_script;
