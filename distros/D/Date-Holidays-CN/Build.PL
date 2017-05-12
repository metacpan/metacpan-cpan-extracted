use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Date::Holidays::CN',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Date/Holidays/CN.pm',
    create_makefile_pl  => 'traditional',
    build_requires => {
        'Test::More' => 0,
        'DateTime'   => 0,
        'DateTime::Calendar::Chinese' => 0,
        
    },
);

$builder->create_build_script();

1;