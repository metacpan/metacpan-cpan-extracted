use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Coro::Twiggy',
    VERSION_FROM      => 'lib/Coro/Twiggy.pm', # finds $VERSION
    PREREQ_PM         => {
            Coro        => '6.07',
            AnyEvent    => 0,
            Twiggy      => '0.1020'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Coro/Twiggy.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
    META_MERGE => {
        resources => {
            homepage => 'https://github.com/unera/coro-twiggy',
            bugtracker => 'https://github.com/unera/coro-twiggy/issues',
        }
    },
    LICENSE => 'perl'
);
