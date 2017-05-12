use strict;
use warnings;
use 5.008;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Date::Korean',
    license             => 'perl',
    dist_author         => 'C.H. Kang <chahkang@gmail.com>',
    dist_version_from   => 'lib/Date/Korean.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'DateTime'   => 0,
        'DateTime::Calendar::Julian' => 0,
        'Date::ISO8601' => 0,
    },
    add_to_cleanup      => [ 'Date-Korean-*' ],
);

$builder->create_build_script();
