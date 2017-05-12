#$Id: Makefile.PL 22 2005-09-10 14:48:45Z kentaro $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Class::AutoAccess::Deep',
    VERSION_FROM      => 'lib/Class/AutoAccess/Deep.pm',
    PREREQ_PM         => {
        Test::More      => 0,
        Test::Exception => 0,
    },
);
