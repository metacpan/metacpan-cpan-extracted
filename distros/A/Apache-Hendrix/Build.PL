use strict;
use warnings;
use Module::Build;

my $build_pkg = eval { require Apache::TestMB } ? 'Apache::TestMB' : 'Module::Build';

my $builder = $build_pkg->new(
    module_name       => 'Apache::Hendrix',
    license           => 'perl',
    dist_author       => 'Zack Allison <zedoriah@gmail.com>',
    dist_version_from => 'lib/Apache/Hendrix.pm',
    requires          => {
        'Test::More'             => 0,
        'version'                => 0,
        'Apache2::Const'         => 0,
        'Apache2::Request'       => 0,
        'Apache2::RequestIO'     => 0,
        'Apache2::RequestRec'    => 0,
        'Carp'                   => 0,
        'JSON::XS'               => 0,
        'Module::Load'           => 0,
        'Moose::Exporter'        => 0,
        'Moose'                  => 0,
        'MooseX::ClassAttribute' => 0,
        'MooseX::FollowPBP'      => 0,
        'MooseX::Singleton'      => 0,
        'Template'               => 0,
        'Tie::Cache'             => 0,
        'TryCatch'               => 0,

    },
    add_to_cleanup => [ 'Apache-Hendrix-*' ],
);

$builder->create_build_script();
