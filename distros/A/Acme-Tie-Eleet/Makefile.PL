#!perl
#
# This file is part of Acme::Tie::Eleet.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

BEGIN { require 5.006; }
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Tie::Eleet',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Tie/Eleet.pm',
    ABSTRACT_FROM       => 'lib/Acme/Tie/Eleet.pm',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Acme-Tie-Eleet-*',
                map { ( '*/' x $_ ) . '*~' } 0..4
                ] },
);
