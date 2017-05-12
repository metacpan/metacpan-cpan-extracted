use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dancer::Plugin::Auth::RBAC::Permissions::DBIC',
    VERSION_FROM      => 'lib/Dancer/Plugin/Auth/RBAC/Permissions/DBIC.pm', # finds $VERSION
    BUILD_REQUIRES => {
        'DBIx::Class::Core' => '0',
        'DBIx::Class::Schema' => '0',
        'File::Temp' => '0',
        'SQL::Translator' => '0.11006',
        'DBD::SQLite' => 0,
        'Test::More' => '0',
        'ok' => '0'
    },
    PREREQ_PM         => {
        'Dancer::Plugin::Auth::RBAC::Credentials::DBIC' => 0,
        'Dancer::Plugin::Auth::RBAC::Permissions' => 0,
        'Dancer::Plugin::DBIC' => '0.15',
        'parent' => '0'
        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Dancer/Plugin/Auth/RBAC/Permissions/DBIC.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);
