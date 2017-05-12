

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Dancer::Plugin::PasswordRequirements',
    VERSION_FROM => 'lib/Dancer/Plugin/PasswordRequirements.pm', # finds \$VERSION
    AUTHOR       => 'Ross Hayes (ross@abablabab.co.uk)',
    ABSTRACT     => 'Configurable password complexity testing',
    PREREQ_PM    => {
                            "Dancer"                 => 0,
                            "Dancer::Plugin"         => 0,
                            "Data::Password::Simple" => 0.05,
                    },
);
