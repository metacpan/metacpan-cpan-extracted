use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Chess::GameClock::GameClock',
    license             => 'perl',
    dist_author         => 'Charles Minc <charles.minc@wanadoo.fr>',
    dist_version   => '1.0',
    dist_abstract   =>'lib/Chess/GameClock/GameClock.pm',
    build_requires => {
        'Test::More' => 0,
	'Tk' =>0,
    },
    add_to_cleanup      => [ 'Chess-GameClock-GameClock-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
