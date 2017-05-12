use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Charsets::Japanese',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Charsets/Japanese.pm', # finds $VERSION
    PREREQ_PM         => {
        Jcode        => 0,
        Catalyst    => 5.23,
    },
);
