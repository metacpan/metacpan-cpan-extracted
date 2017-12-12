use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Random::Flexible',
    AUTHOR           => q{Paul G Webster <daemon@cpan.org>},
    VERSION_FROM     => 'lib/Data/Random/Flexible.pm',
    ABSTRACT_FROM    => 'lib/Data/Random/Flexible.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
        'Try::Tiny'       =>  0,
        'Module::Runtime' =>  0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Random-Flexible-*' },
);
