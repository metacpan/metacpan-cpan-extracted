use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Model::DBIC::Plain',
    AUTHOR    => 'Danijel Milicevic (info@danijel.de)',
    PREREQ_PM => {
        Catalyst           => '5.00',
        DBIx::Class        => '0.01'
    },
    VERSION_FROM => 'lib/Catalyst/Model/DBIC/Plain.pm'
);
