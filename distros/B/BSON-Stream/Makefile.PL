

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'BSON::Stream',
    VERSION_FROM => 'lib/BSON/Stream.pm', # finds \$VERSION
    AUTHOR       => 'Runar Buvik (runarb@gmail.com)',
    ABSTRACT     => 'Read BSON data from stream (file)',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'BSON' => 0,
                    },
);
