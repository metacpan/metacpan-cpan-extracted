use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Audio::Radio::V4L',
    VERSION_FROM => 'lib/Audio/Radio/V4L.pm', # finds $VERSION
    AUTHOR       => 'Nathanael Obermayer (natom-pause@smi2le.net)',
    ABSTRACT     => 'Control a radio via Video4Linux',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
