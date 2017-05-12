use ExtUtils::MakeMaker;
use File::Copy;

#if ($^V lt v5.10) {
#   die("Algorithm::VSM has only been tested on Perl 5.10.0.\n" .
#   "Your perl version is $].\n");
#}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::VSM',
    VERSION_FROM => 'lib/Algorithm/VSM.pm',
    PREREQ_PM    => { Storable => 0,
                      SDBM_File => 0,
                      PDL => 0,
                      File::Basename => 0,
                      File::Spec::Functions => 0,
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl module for retrieving files and documents from a software library with VSM and LSA algorithms',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.b[ac]k *.old *.orig ) )
                    },
);

