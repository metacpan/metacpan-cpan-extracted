use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bot::BasicBot::Pluggable::Module::Eliza',
    dist_author         => 'Mario Domgoergen <dom@math.uni-bonn.de>',
    license             => 'perl',
    requires            => { 
	'Chatbot::Eliza'           => 0, 
	'Bot::BasicBot::Pluggable' => 0.60,
    },
    build_requires      => { 'Test::More'     => 0, },
    add_to_cleanup      => [ 'Bot-BasicBot-Pluggable-Module-Eliza-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
);

$builder->create_build_script();
