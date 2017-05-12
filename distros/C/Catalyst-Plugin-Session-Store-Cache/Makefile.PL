use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Session::Store::Cache',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Session/Store/Cache.pm',
    PREREQ_PM         => {
        'Catalyst::Plugin::Session' => '0.06',
    },
);
