#!perl
#
# This file is part of Acme::MetaSyntactic::buzzwords.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::MetaSyntactic::buzzwords',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Acme/MetaSyntactic/buzzwords.pm',
    ABSTRACT_FROM       => 'lib/Acme/MetaSyntactic/buzzwords.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Acme::MetaSyntactic' => 0,
        'Test::More'          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Acme-MetaSyntactic-buzzwords-*', 'MANIFEST.bak',
                map { ( '*/' x $_ ) . '*~' } 0..5
        ] },
);
