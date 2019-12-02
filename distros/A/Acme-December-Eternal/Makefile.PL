use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::December::Eternal',
    VERSION_FROM      => 'lib/Acme/December/Eternal.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
            'Date::Manip' => 6,
            'Lingua::EN::Numbers::Ordinate' => 1.04,
        },
    ABSTRACT_FROM     => 'lib/Acme/December/Eternal.pm', # retrieve abstract from module
    AUTHOR            => 'Rene Schickbauer <cavac@cpan.org>',
    LICENSE           => 'perl',
);
