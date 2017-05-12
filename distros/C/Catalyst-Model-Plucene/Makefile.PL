use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Model::Plucene',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst        => '2.99',
        Plucene::Simple => 0
    },
    VERSION_FROM => 'Plucene.pm'
);
