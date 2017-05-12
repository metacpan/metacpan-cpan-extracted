#!/usr/bin/perl
#
#   Perl Makefile for Danga-Socket
#   $Id: Makefile.PL 119 2007-05-09 17:59:34Z bradfitz $
#
#   Invoke with 'perl Makefile.PL'
#
#   See ExtUtils::MakeMaker (3) for more information on how to influence
#    the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Danga::Socket',
    VERSION_FROM            => 'lib/Danga/Socket.pm',
    AUTHOR                  => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT                => 'Async socket class',
    PREREQ_PM               => {
        'Socket'        => 0,
        'IO::Poll'      => 0,
        fields          => 0,
        'POSIX'         => 0,
        'Test::More'    => 0,
        'Time::HiRes'   => 0,
        'Sys::Syscall'  => 0,
    },

);

