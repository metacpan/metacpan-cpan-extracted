use 5.14.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Attribute::Boolean',
    AUTHOR           => q{Cliff Stanford <cpan@may.be>},
    VERSION_FROM     => 'lib/Attribute/Boolean.pm',
    ABSTRACT_FROM    => 'lib/Attribute/Boolean.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.14.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Attribute::Handlers'	=> 0,
	'Variable::Magic'	=> 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'attribute-boolean+-*' },
);
