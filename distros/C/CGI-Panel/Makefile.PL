use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::Panel',
    VERSION_FROM => 'lib/CGI/Panel.pm', # finds $VERSION
    AUTHOR       => 'Robert J. Symes (rob@robsymes.com)',
    ABSTRACT     => 'Create sophisticated event-driven web applications from simple panel objects',
    PREREQ_PM    => {
        'Apache::Session::File' => '0'
    }
);
