use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::AutoLoad',
    VERSION_FROM      => 'lib/Acme/AutoLoad.pm', # finds $VERSION
    PREREQ_PM         => {}, # NONE!
    ABSTRACT_FROM     => 'lib/Acme/AutoLoad.pm',
    AUTHOR            => 'Rob Brown (bbb@cpan.org)',
);
