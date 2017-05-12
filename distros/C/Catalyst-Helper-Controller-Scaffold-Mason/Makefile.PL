use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Helper::Controller::Scaffold::Mason',
    AUTHOR    => 'Marcus Ramberg (marcus@thefeed.no)',
    PREREQ_PM => {
        Catalyst                        => '5.23',
        Path::Class                     => 0,
        Class::DBI                      => 0,
        Class::DBI::FromForm            => 0,
        Class::DBI::AsForm              => 0,
        Catalyst::View::Mason		=> 0,
        Catalyst::Plugin::FormValidator => 0,
    },
    VERSION_FROM => 'lib/Catalyst/Helper/Controller/Scaffold/Mason.pm'
);
