use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Convert::CookingTimes',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/Convert/CookingTimes.pm',
    ABSTRACT_FROM    => 'lib/Convert/CookingTimes.pm',
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
        'List::Util' => 0,
        'Lingua::Conjunction' => 0,
        'Math::Round' => 0,

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Convert-CookingTimes-*' },

    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => 'https://github.com/bigpresh/Convert-CookingTimes',
            bugtracker => 'https://github.com/bigpresh/Convert-CookingTimes/issues',
            homepage   => 'https://github.com/bigpresh/Convert-CookingTimes/',
        },
    },

);
