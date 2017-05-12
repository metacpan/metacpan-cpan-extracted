use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::FormValidator::Simple',
    VERSION_FROM      => 'lib/Catalyst/Plugin/FormValidator/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
        Catalyst => 5.30,
        FormValidator::Simple => 0.28,
        Catalyst::Plugin::FormValidator => 0,
    }, # e.g., Module::Name => 1.1
);
