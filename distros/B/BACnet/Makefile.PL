use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => 'BACnet',
    AUTHOR => [
        'Tomas Szaniszlo <xszanisz@fi.muni.cz>',
        'Vojtech Krenek <vojtechkrenek@email.cz>',
    ],
    ABSTRACT =>
'Set of perl modules, which implements functionality of BACnet communication protocol',
    LICENSE   => 'perl',
    PREREQ_PM => {
        'IO::Async::Loop'    => '0.803',
        'IO::Async::Socket'  => '0.803',
        'Future::AsyncAwait' => '0.70'
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.58',
    },
    VERSION_FROM     => 'lib/BACnet.pm',
    MIN_PERL_VERSION => '5.34.0',
    test             => {
        TESTS => 't/*.t t/*/*.t'
    },
);
