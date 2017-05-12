use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::NoCache',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/NoCache.pm', # finds $VERSION
    PREREQ_PM         => { Class::DBI => 0 }, # e.g., Module::Name => 1.1
);
