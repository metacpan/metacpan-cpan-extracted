use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    NAME              => 'Acme::PDF::rescale',
    VERSION_FROM      => 'lib/Acme/PDF/rescale.pm', 
    PREREQ_PM         => { 'Getopt::Lucid' => 0.16 },
    EXE_FILES         => ['bin/pdfrescale'],
);
