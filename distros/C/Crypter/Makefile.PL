#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Crypter',
    AUTHOR			=> 'Ivan Trunaev',
    VERSION_FROM	=> "lib/Crypter.pm",
    EXE_FILES		=> [ './bin/crypter' ],
    PREREQ_PM		=> {'Strong::Random' => 0.9},
);

1;
