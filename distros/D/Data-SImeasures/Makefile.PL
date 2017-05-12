use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::SImeasures',
    AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM        => 'lib/Data/SImeasures.pm',
    ABSTRACT_FROM       => 'lib/Data/SImeasures.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Error::Helper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-SImeasures-*' },
	);
