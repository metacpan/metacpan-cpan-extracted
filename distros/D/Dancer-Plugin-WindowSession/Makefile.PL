use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::WindowSession',
    AUTHOR              => q{Assaf Gordon <gordon@cshl.edu>},
    VERSION_FROM        => 'lib/Dancer/Plugin/WindowSession.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/WindowSession.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer' => 1.3000,
        'Clone' => 0,
	'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-WindowSession-*' },
);
