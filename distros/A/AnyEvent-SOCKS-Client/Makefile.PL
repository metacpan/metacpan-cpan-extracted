use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AnyEvent::SOCKS::Client',
    AUTHOR           => q{user <zlobus@cpan.org>},
    VERSION_FROM     => 'lib/AnyEvent/SOCKS/Client.pm',
    ABSTRACT_FROM    => 'lib/AnyEvent/SOCKS/Client.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'AnyEvent' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'AnyEvent-SOCKS-Client-*' },
);
