use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::General::Match',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/Config/General/Match.pm',
    requires => {
        'Test::More'      => 0,
        'Config::General' => 0,
        'Hash::Merge'     => 0,
    },                         
    add_to_cleanup      => [ 'Config-General-Match-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
