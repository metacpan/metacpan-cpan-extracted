use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::Wiki::Plugin::Locator::UTM',
    VERSION_FROM => 'lib/CGI/Wiki/Plugin/Locator/UTM.pm', # finds $VERSION
    AUTHOR       => 'Ivor Williams (ivorw at CPAN dot org)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'CGI::Wiki' => 0,
                     'Geo::Coordinates::UTM' => 0,
                    },
);
