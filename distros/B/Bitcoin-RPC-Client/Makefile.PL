use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bitcoin::RPC::Client',
    AUTHOR           => q{Wesley Hinds <wesley.hinds@gmail.com>},
    VERSION_FROM     => 'lib/Bitcoin/RPC/Client.pm',
    ABSTRACT_FROM    => 'lib/Bitcoin/RPC/Client.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'               => 1.001,
        'JSON::RPC::Client' => 0.93,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bitcoin-*' },
);
