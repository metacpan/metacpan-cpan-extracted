use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::Class::TimeStamp::WithTimeZone',
    VERSION_FROM => 'lib/DBIx/Class/TimeStamp/WithTimeZone.pm',
    PREREQ_PM    => {
        'DateTime' => 1.18,
        # We're an actual subclass of DBIx::Class::TimeStamp
        'DBIx::Class::TimeStamp' => '0.14',
    },
    LICENSE => 'perl_5',
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM => 'lib/DBIx/Class/TimeStamp/WithTimeZone.pm',
            AUTHOR => 'Javier Arturo Rodriguez <javier@rodriguez.org.mx>',
            )
        : ()
    ),
);
