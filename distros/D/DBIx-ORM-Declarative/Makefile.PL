use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::ORM::Declarative',
    VERSION_FROM      => 'lib/DBIx/ORM/Declarative.pm',
    AUTHOR            => 'Jim Schneider <perl@jrcsdevelopment.com>',
    ABSTRACT_FROM     => 'lib/DBIx/ORM/Declarative.pod',
    PREREQ_PM         => { DBI => 1.30, 'Scalar::Util' => 1 },
    PL_FILES          => { },
);
