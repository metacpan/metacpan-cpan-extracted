#!/usr/bin/perl

use ExtUtils::MakeMaker;

my %config = (
    NAME            => 'DDLock::Client',
    VERSION_FROM    => 'lib/DDLock/Client.pm',
    AUTHOR          => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT_FROM   => 'lib/DDLock/Client.pm',
    PREREQ_PM       => {
        constant    => 0,
        fields      => 0,
        lib         => 0,
        strict      => 0,
        warnings    => 0,

        Data::Dumper        => 0,
        ExtUtils::MakeMaker => 0,
        Fcntl               => 0,
        File::Path          => 0,
        File::Spec          => 0,
        IO::File            => 0,
        IO::Socket::INET    => 0,
        Socket              => 0,
        Test                => 0,
        Test::More          => 0,
    },
);


WriteMakefile( %config );
