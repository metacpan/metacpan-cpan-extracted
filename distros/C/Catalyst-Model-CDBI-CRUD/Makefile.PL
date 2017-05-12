use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Model::CDBI::CRUD',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst                        => '2.99',
        Catalyst::Model::CDBI           => 0,
        Class::DBI                      => 0,
        Class::DBI::Loader              => 0,
        Class::DBI::FromForm            => 0,
        Class::DBI::AsForm              => 0,
        Class::DBI::Plugin::RetrieveAll => 0,
        Catalyst::View::TT              => 0,
        Template::Plugin::Class         => 0
    },
    VERSION_FROM => 'CRUD.pm'
);
