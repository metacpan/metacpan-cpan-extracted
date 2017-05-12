use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Convert::Bencode',
    VERSION_FROM => 'lib/Convert/Bencode.pm', # finds $VERSION
    AUTHOR       => 'R. Kyle Murphy (orclev@rejectedmaterial.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::More' => 0.45,
                    },
);
