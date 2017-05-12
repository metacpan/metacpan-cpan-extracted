

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::DBI::Pg::More',
    VERSION_FROM => 'lib/Class/DBI/Pg/More.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Enhances Class::DBI::Pg with more goodies',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::TempDatabase' => '0.12',
		     'Class::DBI::Plugin::DateTime::Pg' => ''
                    },
);
