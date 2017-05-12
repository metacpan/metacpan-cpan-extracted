

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::123',
    VERSION_FROM => 'lib/Acme/123.pm', # finds \$VERSION
    AUTHOR       => 'Nathan McClurg ()',
    ABSTRACT     => 'Acme::123 - Prints numbers in different languages',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
