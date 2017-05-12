use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Catalyst::Helper::Doc',
    VERSION_FROM      => 'lib/Catalyst/Helper/Doc.pm', # finds $VERSION
    PREREQ_PM         => {
      Pod::ProjectDocs => 0.22,
      Catalyst         => 5.3
    }, # e.g., Module::Name => 1.1
);
