use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::EncodeID',
    AUTHOR              => q{Assaf Gordon <gordon@cshl.edu>},
    VERSION_FROM        => 'lib/Dancer/Plugin/EncodeID.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/EncodeID.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer' => 1.3000,
        'Test::More' => 0,
	'Crypt::Blowfish' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-EncodeID-*' },
);
