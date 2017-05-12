use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::Authentication::CDBI',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst                            => '2.99',
        Catalyst::Model::CDBI               => 0,
        Catalyst::Plugin::Session::FastMmap => 0,
    },
    VERSION_FROM => 'CDBI.pm'
);
