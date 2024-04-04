use strict;
use warnings;

return {
    NAME               => 'Data::Munge',
    AUTHOR             => q{Lukas Mai <l.mai@web.de>},

    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES     => {},
    TEST_REQUIRES      => {
        'Test2::V0' => 0,
    },
    PREREQ_PM          => {
        'strict'   => 0,
        'warnings' => 0,
    },
    DEVELOP_REQUIRES   => {
        'Test::Pod' => 1.22,
    },

    REPOSITORY         => [ github => 'mauke' ],
};
