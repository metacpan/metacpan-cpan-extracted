use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::CSRF',
    AUTHOR           => q{Oleg Nurtdinov <jumpercc@cpan.org>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/CSRF.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/CSRF.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
		'Dancer2'           => '0.200001',
		'Crypt::SaltedHash' => 0,
		'Data::UUID'        => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-CSRF-*' },
);
