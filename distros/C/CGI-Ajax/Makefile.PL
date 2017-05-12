

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::Ajax',
    VERSION_FROM => 'lib/CGI/Ajax.pm', # finds \$VERSION
    AUTHOR       => 'Brian C. Thomas (bct.x42@gmail.com) Brent Pedersen (bpederse@gmail.com)',
    ABSTRACT     => 'CGI::Ajax',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Class::Accessor' => 0,
                     'CGI' => 0
                    },
);
