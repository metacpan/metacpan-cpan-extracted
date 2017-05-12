use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::MySQL',
    AUTHOR              => q{Cindy Wang (CindyLinz)},
    VERSION_FROM        => 'lib/AnyEvent/MySQL.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/MySQL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyEvent' => 0,
        'Digest::SHA1' => 0,
        'Guard' => 0,
        'Devel::StackTrace' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-MySQL-*' },
);
