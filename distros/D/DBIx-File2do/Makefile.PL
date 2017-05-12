

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::File2do',
    VERSION_FROM => 'File2do.pm', # finds \$VERSION
    AUTHOR       => 'Jack Bilemjian (jck000@gmail.com)',
    ABSTRACT     => 'Execute SQL scripts from Perl.',
    PREREQ_PM    => {
                     'DBI' => 1.40,
                     'Test::Simple' => 0.44,
                    },
);



