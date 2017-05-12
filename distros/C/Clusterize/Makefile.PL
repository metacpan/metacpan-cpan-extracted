use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Clusterize',
    AUTHOR              => q{Slava Moiseev <slava.moiseev@yahoo.com>},
    VERSION_FROM        => 'lib/Clusterize.pm',
    ABSTRACT_FROM       => 'lib/Clusterize.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Digest::MD5' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Clusterize-*' },
);
