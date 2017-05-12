use ExtUtils::MakeMaker;

WriteMakefile (NAME => "DBIx::POS",
               VERSION_FROM => "lib/DBIx/POS.pm",
               PREREQ_PM => {Pod::Parser => 0},
               ($] >= 5.005 ?
                (ABSTRACT_FROM => "lib/DBIx/POS.pm",
                 AUTHOR => "Michael Alan Dorman <mdorman@debian.org>") : ()));
