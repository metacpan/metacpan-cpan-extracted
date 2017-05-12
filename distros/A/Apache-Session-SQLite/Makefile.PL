use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Apache::Session::SQLite',
    'VERSION_FROM' => 'lib/Apache/Session/SQLite.pm', # finds $VERSION
    'PREREQ_PM' => {
        'Test::More'      => 0.32,
        'Apache::Session' => 1.53,
        'DBD::SQLite'     => 0.15,
    },
);
