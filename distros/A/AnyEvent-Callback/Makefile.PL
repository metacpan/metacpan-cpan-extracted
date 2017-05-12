use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'AnyEvent::Callback',
    VERSION_FROM    => 'lib/AnyEvent/Callback.pm',
    PREREQ_PM       => {},
    BUILD_REQUIRES  => {
        AnyEvent    => 0,
    },
    ABSTRACT_FROM   => 'lib/AnyEvent/Callback.pm',
    AUTHOR          => 'Dmitry E. Oboukhov <unera@debian.org>',
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/unera/libanyevent-callback',
            bugtracker =>
                'https://github.com/unera/libanyevent-callback/issues',
        }
    },
    LICENSE => 'perl'
);
