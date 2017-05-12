

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DateTimeX::AATW',
    VERSION_FROM => 'lib/DateTimeX/AATW.pm', # finds \$VERSION
    AUTHOR       => 'Kevin C. McGrath (kmcgrath@baknet.com)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'DateTime'     => 0.50,
                     'DateTime::TimeZone' => 0.91,
                    },
);
