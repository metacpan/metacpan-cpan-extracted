use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Bot::BasicBot::Pluggable::Module::Log',
    license           => 'perl',
    dist_author       => 'Mario Domgoergen <dom@math.uni-bonn.de>',
    dist_version_from => 'lib/Bot/BasicBot/Pluggable/Module/Log.pm',
    requires          => {
        'autodie'    => 0,
        'POSIX'      => 0,
        'File::Spec' => 0,
	'Bot::BasicBot::Pluggable' => '0.77',
    },
    build_requires     => { 'Test::More' => 0 },
    add_to_cleanup     => ['Bot-BasicBot-Pluggable-Module-Log-*'],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);

$builder->create_build_script();
