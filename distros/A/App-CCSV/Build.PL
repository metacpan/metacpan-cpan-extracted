use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::CCSV',
    license             => 'perl',
    requires		=> { 'Text::CSV_XS'  => 0, 'Config::General' => 0 },
    dist_author         => 'Karlheinz Zoechling <kh@ibeatgarry.com>',
    dist_version_from   => 'lib/App/CCSV.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'App-CCSV-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
