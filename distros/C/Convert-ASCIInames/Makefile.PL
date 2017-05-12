use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Convert::ASCIInames',
    VERSION_FROM => 'lib/Convert/ASCIInames.pm', # finds $VERSION
    AUTHOR       => 'Ken Coar (Ken.Coar@Golux.Com)',
    ABSTRACT     => 'Convert::ASCIInames',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
