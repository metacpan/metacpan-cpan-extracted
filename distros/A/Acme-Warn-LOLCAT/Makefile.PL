use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Warn::LOLCAT',
    VERSION_FROM      => 'lib/Acme/Warn/LOLCAT.pm', # finds $VERSION
    PREREQ_PM         => {
        'Acme::LOLCAT' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Warn/LOLCAT.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Aquilina <aquilina@cpan.org>') : ()),
);
