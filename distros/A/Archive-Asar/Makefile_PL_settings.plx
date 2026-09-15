# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME    => 'Archive::Asar',
    AUTHOR  => q{Lukas Mai <l.mai@web.de>},
    LICENSE => 'gpl_3',

    MIN_PERL_VERSION => '5.36.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    PREREQ_PM => {
        'constant' => 0,
        'Carp'     => 0,
        'Fcntl'    => 0,
        'JSON::PP' => 0,
    },
    RECOMMENDS => {
        'Cpanel::JSON::XS' => 0,
    },
    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },
    DEVELOP_REQUIRES   => {
        'Test::Pod' => 1.22,
    },

    depend => {
        Makefile => '$(VERSION_FROM)',
    },

    REPOSITORY => [ codeberg => 'mauke' ],
};
