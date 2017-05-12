use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'BitArray',
    VERSION_FROM => 'lib/BitArray.pm', # finds $VERSION
    AUTHOR       => 'George E. Worroll Jr. (geworrolljr@optonline.net)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
