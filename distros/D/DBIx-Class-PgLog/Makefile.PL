use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Class::PgLog',
    AUTHOR           => q{Sheeju Alex <sheeju@exceleron.com>},
    VERSION_FROM     => 'lib/DBIx/Class/PgLog.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Class/PgLog.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Class::C3::Componentised' => 0,
        'DBIx::Class'              => 0,
        'MooseX::MarkAsMethods'    => 0,
        'MooseX::NonMoose'         => 0,
        'Scalar::Util'             => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Class-PgLog-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/sheeju/DBIx-Class-PgLog.git',
				web => 'https://github.com/sheeju/DBIx-Class-PgLog',
			},
		},
	},
	'LICENSE'  => 'perl',
);
