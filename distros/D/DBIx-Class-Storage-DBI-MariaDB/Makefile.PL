use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => "DBIx::Class::Storage::DBI::MariaDB",
    AUTHOR => [
        'Antonis Kalou <a.kalou@shadowcat.co.uk>',
        'Jess Robinson <j.robinson@shadowcat.co.uk>',
    ],
    LICENSE    => "perl_5",
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => "git",
                url  => "https://github.com/Siemplexus/DBIx-Class-Storage-DBI-MariaDB.git",
                web => "https://github.com/Siemplexus/DBIx-Class-Storage-DBI-MariaDB",
            },
            bugtracker => {
                web => "https://github.com/Siemplexus/DBIx-Class-Storage-DBI-MariaDB/issues",
            },
        },
        x_contributors => [
          'Dave Lambley <dave@lambley.me.uk>',
        ],
    },
    VERSION_FROM => "lib/DBIx/Class/Storage/DBI/MariaDB.pm",
    PREREQ_PM    => {
        'DBD::MariaDB' => '>= 1.00',
        'DBIx::Class'  => '>= 0.082820',
        'DBI'          => 0,
        'perl'         => '>= 5.8.9',
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
        'Test::Warn'      => 0,
        'Test::Exception' => 0,
        'SQL::Translator' => 0,
    },
  )
