use ExtUtils::MakeMaker;
WriteMakefile(
            NAME => 'Bundle::MusicBrainz::Server',
    VERSION_FROM => 'lib/Bundle/MusicBrainz/Server.pm',
          'dist' => {
                COMPRESS => 'gzip -9f',
                SUFFIX   => '.gz', 
            DIST_DEFAULT => 'all tardist',
               },

);
