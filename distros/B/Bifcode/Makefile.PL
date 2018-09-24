#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME         => 'Bifcode',
    ABSTRACT     => 'Simple serialization format',
    AUTHOR       => 'Mark Lawrencde <nomad@null.net>',
    VERSION_FROM => 'lib/Bifcode.pm',
    LICENSE      => 'perl_5',
    EXE_FILES    => ['bin/diff-bifcode'],
    META_ADD     => {
        resources => {
            repository => 'https://github.com/mlawren/p5-Bifcode',
        }
    },
    META_MERGE => {
        no_index => {
            package => [qw(Bifcode::Boolean)],
        },
    },
);
