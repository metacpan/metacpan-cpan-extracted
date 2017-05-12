use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'DBIx::Oracle::Unwrap',
    AUTHOR             => q{Dan Horne <dhorne at cpan.org>},
    VERSION_FROM       => 'lib/DBIx/Oracle/Unwrap.pm',
    ABSTRACT_FROM      => 'lib/DBIx/Oracle/Unwrap.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    EXE_FILES          => ['script/unwrap'],
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 0,},
    BUILD_REQUIRES     => {'Test::More' => 0,},
    PREREQ_PM          => {
	'Readonly'      => 0,
	'File::Slurp'   => 0,
	'Capture::Tiny' => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'DBIx-Oracle-Unwrap-*'},
);
