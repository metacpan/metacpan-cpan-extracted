use 5.010;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Apache::Session::MongoDB',
    VERSION_FROM => 'lib/Apache/Session/MongoDB.pm',
    PREREQ_PM    => {
        'Apache::Session' => '1.80',
        MongoDB           => 0,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Apache/Session/MongoDB.pm',
            AUTHOR        => 'Xavier Guimard <x.guimard@free.fr>'
          )
        : ()
    ),
);
