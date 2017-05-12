# Makefile.PL for CPANPLUS::Shell::Default::Plugins::Changes

use ExtUtils::MakeMaker;

use strict;
use warnings;

WriteMakefile(
    NAME         => 'CPANPLUS::Shell::Default::Plugins::Changes',
    VERSION_FROM => 'lib/CPANPLUS/Shell/Default/Plugins/Changes.pm',
    PREREQ_PM    => { 'CPANPLUS' => '0.059', },
    AUTHOR       => 'Arjen Laarhoven <arjen@cpan.org>',
    ABSTRACT     => 'CPANPLUS shell plugin for displaying the Changes file',
);
