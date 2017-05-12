use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Barcode::Code128',
              VERSION_FROM => 'lib/Barcode/Code128.pm', # finds $VERSION
              PREREQ_PM    => { 'Test::More' => 0, 'File::Spec' => 0, },
             );
