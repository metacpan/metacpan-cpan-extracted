use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'CatalystX::PathContext',
    license           => 'perl',
    dist_author       => q{Andreas 'ac0v' Specht <ac0v@sys-network.de>},
    dist_version_from => 'lib/CatalystX/PathContext.pm',
    requires => {
        'Test::More'          => 0,
        'version'             => 0,
        'Moose::Role'         => 0,
        'Catalyst::Exception' => 0,
    },
    build_requires => {
        'Catalyst::Controller'    => 0,
        'Moose'                   => 0,
        'Catalyst'                => 0,
        'Catalyst::Runtime'       => 5.80,
        'Catalyst::Test'          => 0,
        'Tie::Hash::NamedCapture' => 0,
    },
    add_to_cleanup => [ 'CatalystX-PathContext-*' ],
    perl_version   => '5.010000',
);

$builder->create_build_script();
