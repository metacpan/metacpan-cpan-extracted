use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Acme::Shotgun',
    license            => 'perl',
    dist_author        => 'John R. <johnlradford23@gmail.com>',
    requires => {
        'perl'           => '5.010',
    },
    build_requires => {
        'Module::Build'   => 0,
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    resources => {
        repository => {
            type => 'git',
            url  => 'git@github.com:BlueSquare23/Acme-Shotgun.git',
            web  => 'https://github.com/BlueSquare23/Acme-Shotgun',
        },
        bugtracker => {
            web => 'https://github.com/BlueSquare23/Acme-Shotgun/issues',
        },
    },
);

$build->create_build_script();
