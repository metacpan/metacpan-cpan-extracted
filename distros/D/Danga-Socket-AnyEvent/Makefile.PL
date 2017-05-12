#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Danga::Socket::AnyEvent',
    VERSION_FROM            => 'lib/Danga/Socket/AnyEvent.pm',
    AUTHOR                  => 'Martin Atkins <mart@degeneration.co.uk>',
    ABSTRACT                => 'Reimplementation of Danga::Socket in terms of AnyEvent',
    PREREQ_PM               => {
        'AnyEvent'      => 1,
        fields          => 0,
        'POSIX'         => 0,
        'Test::More'    => 0,
        'Time::HiRes'   => 0,
        'Sys::Syscall'  => 0,
        'Carp'          => 0,
    },
    PM => {
        "lib/Danga/Socket/AnyEvent.pm" => (
            '$(INST_LIBDIR)/AnyEvent.pm',
        ),
    },
);

