use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => "Bot::BasicBot::Pluggable::Module::PasteBin",
    license           => 'perl',
    dist_author       => q{Frederico Recsky <frederico@gmail.com>},
    dist_version_from => 'lib/Bot/BasicBot/Pluggable/Module/PasteBin.pm',
    requires      => {
        'LWP::UserAgent'           => 0,
        'HTML::LinkExtractor'      => 0,
        'Test::More'               => 0,
        'Bot::BasicBot::Pluggable' => '0.5',
    },
    add_to_cleanup => ['Bot-BasicBot-Pluggable-Module-PasteBin-*'],
);

$build->create_build_script;

