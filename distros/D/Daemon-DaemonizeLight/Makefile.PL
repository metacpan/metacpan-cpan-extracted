

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Daemon::DaemonizeLight',
    VERSION_FROM => 'lib/Daemon/DaemonizeLight.pm', # finds \$VERSION
    AUTHOR       => 'Evgeniy Bulichev (bes@cpan.org)',
    ABSTRACT     => 'Make daemon from any perl script',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'FindBin' => 1.51,
                     'Proc::ProcessTableLight' => 0
                    },
);
