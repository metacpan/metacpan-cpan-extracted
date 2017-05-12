use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Date::Holidays::BR',
    license             => 'perl',
    dist_author         => q{Breno G. de Oliveira <garu@cpan.org>},
    dist_version_from   => 'lib/Date/Holidays/BR.pm',
    dist_abstract       => 'Determine Brazilian public holidays',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Date::Holidays::Super' => 0,
        'Date::Easter' => 0,
        'Time::JulianDay' => 0,
    },
    add_to_cleanup      => [ 'Date-Holidays-BR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
