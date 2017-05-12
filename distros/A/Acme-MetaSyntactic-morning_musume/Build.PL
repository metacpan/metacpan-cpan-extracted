use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name    => 'Acme::MetaSyntactic::morning_musume',
    dist_author    => 'Laurent Boivin (elbeho) <elbeho@cpan.org>',
    dist_abstract  => 'Theme Morning Musume for AMS. Data from Acme::MorningMusume',
    license        => 'perl',
    build_requires => {
        'Test::More'          => '0.94',
        'Test::MetaSyntactic' => '1.001',
    },
    requires => {
        'Acme::MetaSyntactic' => '1.007',
        'Acme::MorningMusume' => '0.13',
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/elbeho/Acme-MetaSyntactic-morning_musume',
        },
    },
    recommends     => {},
    add_to_cleanup => ['Acme-MetaSyntactic-morning_musume-*'],
);

$build->create_build_script;

