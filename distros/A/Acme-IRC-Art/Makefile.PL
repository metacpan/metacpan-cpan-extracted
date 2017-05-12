use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::IRC::Art',
    VERSION_FROM => 'lib/Acme/IRC/Art.pm', # finds $VERSION
    AUTHOR       => 'Colinet Sylvain (skarsnikum@free.fr)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
