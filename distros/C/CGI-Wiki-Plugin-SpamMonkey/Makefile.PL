

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::Wiki::Plugin::SpamMonkey',
    VERSION_FROM => 'lib/CGI/Wiki/Plugin/SpamMonkey.pm', # finds \$VERSION
    AUTHOR       => 'Ivor Williams (ivorw-openguides@xemaps.com)',
    ABSTRACT_FROM => 'lib/CGI/Wiki/Plugin/SpamMonkey.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'SpamMonkey'   => 0,
                     'CGI::Wiki'    => 0.44,
                    },
);
