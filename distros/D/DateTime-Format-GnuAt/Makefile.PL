use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'DateTime::Format::GnuAt',
               VERSION_FROM  => 'lib/DateTime/Format/GnuAt.pm',
               PREREQ_PM     => { 'DateTime' => 0 },
               ABSTRACT_FROM => 'lib/DateTime/Format/GnuAt.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>');
