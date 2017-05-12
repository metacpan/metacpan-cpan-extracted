use ExtUtils::MakeMaker;
WriteMakefile(
        NAME            => 'Bundle::SDK::SIMON',
        VERSION_FROM    => 'SIMON.pm',
        ABSTRACT_FROM    => 'SIMON.pm',
        'dist'          => {
                                COMPRESS => 'gzip -9f',
                                SUFFIX   => '.gz',
                                DIST_DEFAULT => 'all tardist',
                           },

);
