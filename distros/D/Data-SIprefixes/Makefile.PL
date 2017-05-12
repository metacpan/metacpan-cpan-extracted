use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::SIprefixes',
    AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM        => 'lib/Data/SIprefixes.pm',
    ABSTRACT_FROM       => 'lib/Data/SIprefixes.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'=>0,
		'Math::BigInt'=>0,
		'Math::BigFloat'=>0,
		'bignum'=>0,
		'Error::Helper'=>0,
		'Module::List'=>0,
		'Data::SImeasures'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-SIprefixes-*' },
	);
