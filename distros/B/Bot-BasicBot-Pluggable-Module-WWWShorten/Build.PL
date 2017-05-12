use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Bot::BasicBot::Pluggable::Module::WWWShorten',
    license           => 'perl',
    dist_author       => q{Mario Domgoergen <mdom@cpan.org>},
    dist_version_from => 'lib/Bot/BasicBot/Pluggable/Module/WWWShorten.pm',
    requires          => {
        'parent'                   => 0,
        'Bot::BasicBot::Pluggable' => '0.81',
        'URI::Find::Rule'          => 0,
        'Try::Tiny'                => 0,
        'Module::Load'             => 0,
        'LWP::UserAgent'           => 0,
    },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Bot-BasicBot-Pluggable-Module-WWWShorten-*'],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    meta_merge         => {
        resources => {
            repository =>
              'http://github.com/mdom/bot-basicbot-pluggable-module-wwwshorten',
        },
      }

);

$builder->create_build_script();
