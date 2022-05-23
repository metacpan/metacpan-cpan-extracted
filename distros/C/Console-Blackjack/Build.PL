use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Console::Blackjack',
    license             => 'artistic_2',
    dist_author         => q{Greg Donald <gdonald@gmail.com>},
    dist_version_from   => 'lib/Console/Blackjack.pm',
    script_files        => 'script/console-blackjack.pl',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Storable' => '3.25',
    },
    add_to_cleanup     => [ 'Console-Blackjack-*' ],
);

$builder->create_build_script();
