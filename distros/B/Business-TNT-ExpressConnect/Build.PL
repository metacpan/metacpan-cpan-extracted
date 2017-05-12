use strict;
use warnings;
use Module::Build::SysPath;

use 5.010;

my $builder = Module::Build::SysPath->new(
    module_name       => 'Business-TNT-ExpressConnect',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Business/TNT/ExpressConnect.pm',

    configure_requires => {
        'Module::Build::SysPath' => 0.13,
        'Module::Build'          => '0.3607',
    },
    build_requires => {
        'Module::Build::SysPath' => 0.13,
        'Test::Most'             => 0,
    },
    requires => {
        'perl'                 => '5.010',
        'Path::Class'          => 0.04,      # mkpath()
        'DateTime'             => 0,
        'Config::INI::Reader'  => 0,
        'XML::Compile::Schema' => 0,
        'XML::Compile::Util'   => 0,
        'LWP::UserAgent'       => 0,
        'Moose'                => 0,
        'DateTime'             => 0,
    },
    script_files => [qw(
            )
    ],
    conffiles => [qw(
            )
    ],
    add_to_cleanup => ['Business-TNT-ExpressConnect-*'],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/meon/Business-TNT-ExpressConnect.git',
            bugtracker => 'https://github.com/meon/Business-TNT-ExpressConnect/issues',
        },
        keywords => [ qw/ TNT ExpressConnect shipping price / ],
    },
);

$builder->create_build_script();
