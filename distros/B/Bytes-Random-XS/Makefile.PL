#
# Copyright (C) 2017 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.24.0 or,
# at your option, any later version of Perl 5 you may have available.
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Bytes::Random::XS',
    AUTHOR => q{Tomasz Konojacki <me@xenu.pl>},
    VERSION_FROM => 'lib/Bytes/Random/XS.pm',
    ABSTRACT_FROM => 'lib/Bytes/Random/XS.pm',
    LICENSE => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/xenu/bytes-random-xs.git',
                web => 'https://github.com/xenu/bytes-random-xs',
            }
        },
    },
    MIN_PERL_VERSION => '5.008008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Exporter::Lite' => 0,
        'XSLoader' => 0
    },

);
