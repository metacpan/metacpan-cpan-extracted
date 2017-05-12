

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::FR::RIB',
    VERSION_FROM => 'lib/Business/FR/RIB.pm', # finds \$VERSION
    AUTHOR       => 'Luc DIDRY (ldidry@cpan.org)',
    ABSTRACT     => 'Verify French RIB (Relevé d\'Identite Bancaire)',
    PREREQ_PM    => {
                     'Test::Simple'        => 0.44,
                     'Test::CheckManifest' => 0.9,
                     'Test::Pod::Coverage' => 1.08,
                     'Test::Pod'           => 0.18,
                    },
);
