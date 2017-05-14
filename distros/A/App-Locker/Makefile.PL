

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'App::Locker',
    VERSION_FROM => 'lib/App/Locker.pm', # finds \$VERSION
    AUTHOR       => 'Evgeniy Bulichev (bes@cpan.org)',
    ABSTRACT     => 'Lock/Unlock any perl script',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Storable' => 2.45,
                     'Convert::Base64' => 0.001,
                     'IO::Handle' => 1.33
                    },
);
