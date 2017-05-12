use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bot::BasicBot::Pluggable::Module::VieDeMerde',
    license             => 'perl',
    dist_author         => 'Olivier Schwander <iderrick@cpan.org>',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'WWW::VieDeMerde' => 0.21,
        'Bot::BasicBot::Pluggable' => 0,
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

