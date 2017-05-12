#!/usr/bin/perl

use ExtUtils::MakeMaker;

my %config = (
    NAME            => 'DDLock::Server',
    VERSION_FROM    => 'lib/DDLock/Server.pm',
    AUTHOR          => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT_FROM   => 'lib/DDLock/Server.pm',
    EXE_FILES       => [ 'ddlockd' ],
    PREREQ_PM       => {
        base        => 0,
        constant    => 0,
        fields      => 0,
        lib         => 0,
        strict      => 0,
        vars        => 0,
        warnings    => 0,

        Carp                => 0,
        Danga::Socket       => 0,
        Errno               => 0,
        ExtUtils::MakeMaker => 0,
        Fcntl               => 0,
        DBI                 => 0,
        Getopt::Long        => 0,
        IO::Socket::INET    => 0,
        POSIX               => 0,
        Socket              => 0,
    },
);

WriteMakefile( %config );
