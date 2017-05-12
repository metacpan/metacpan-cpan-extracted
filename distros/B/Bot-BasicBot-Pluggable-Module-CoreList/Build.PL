use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => "Bot::BasicBot::Pluggable::Module::CoreList",
    license           => 'perl',
    dist_author       => q{Philippe "BooK" Bruhat <book@cpan.org>},
    dist_version_from => 'lib/Bot/BasicBot/Pluggable/Module/CoreList.pm',
    requires      => {
        'Test::More'               => 0,
        'Bot::BasicBot::Pluggable' => '0.5',
        'Module::CoreList'         => '2.18',
    },
    add_to_cleanup => ['Bot-BasicBot-Pluggable-Module-CoreList-*'],
);

$build->create_build_script;

