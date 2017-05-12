use utf8;
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AnyEvent::XMLRPC',
    AUTHOR           => q{BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>},
    VERSION_FROM     => 'lib/AnyEvent/XMLRPC.pm',
    ABSTRACT_FROM    => 'lib/AnyEvent/XMLRPC.pm',
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
        'AnyEvent::HTTPD'   => 0.6,
        'Frontier::RPC2'    => 0,
        'common::sense'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'AnyEvent-XMLRPC-*' },
);
