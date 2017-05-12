use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::DR',
    VERSION_FROM      => 'lib/DBIx/DR.pm', # finds $VERSION
    PREREQ_PM         => {
        DBI         => 1.4,
        Mouse       => 0,
    },
    ABSTRACT_FROM  => 'lib/DBIx/DR.pm', # retrieve abstract from module
    AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>',

    BUILD_REQUIRES      => {
       'DBD::SQLite'  =>  1.0
    },
    LICENSE           => 'Artistic License',

    META_MERGE  => {
        resources => {
            repository => 'https://github.com/dr-co/dbix-dr',
            bugtracker => 'https://github.com/dr-co/dbix-dr/issues'
        }
    }
);

