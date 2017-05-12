use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Helper::Controller::Scaffold',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst                        => '5.23',
        Path::Class                     => 0,
        Class::DBI                      => 0,
        Class::DBI::FromForm            => 0,
        Class::DBI::AsForm              => 0,
        Catalyst::View::TT              => 0,
        Catalyst::Plugin::FormValidator => 0,
        Template::Plugin::Class         => 0
    },
    VERSION_FROM => 'lib/Catalyst/Helper/Controller/Scaffold.pm'
);
