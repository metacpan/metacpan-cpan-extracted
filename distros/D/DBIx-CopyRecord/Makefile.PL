

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::CopyRecord',
    VERSION_FROM => 'CopyRecord.pm', # finds \$VERSION
    AUTHOR       => 'Jack Bilemjian (jck000@gmail.com)',
    ABSTRACT     => 'Copy Records while maintaining referential integrity within a database.',
    PREREQ_PM    => {
                     'DBI' => 1.40,
                     'Test::Simple' => 0.44,
                    },
);
