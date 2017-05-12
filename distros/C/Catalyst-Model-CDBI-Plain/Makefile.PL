use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Model::CDBI::Plain',
    AUTHOR    => 'Jesse Sheidlower (jester@panix.com)',
    PREREQ_PM => {
        Catalyst           => '5.00',
        Class::DBI         => 0
    },
    VERSION_FROM => 'lib/Catalyst/Model/CDBI/Plain.pm'
);
