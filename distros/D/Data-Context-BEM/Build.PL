use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::Context::BEM',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Data/Context/BEM.pm',
    requires          => {
        'perl'                    => '5.006',
        'Data::Context'           => '0.2',
        'Data::Context::Actions'  => '0.2',
        'Data::Context::Instance' => '0.2',
        'Data::Context::Log'      => '0.2',
        'File::ShareDir'          => 0,
        'JSON::XS'                => 0,
        'List::MoreUtils'         => 0,
        'List::Util'              => 0,
        'Moose'                   => 0,
        'Path::Tiny'              => 0,
        'Scalar::Util'            => 0,
        'Template'                => 0,
        'namespace::autoclean'    => 0,
        'version'                 => 0,
    },
    build_requires => {
        'Test::More'       => '0.88',
        'Test::NoWarnings' => 0,
    },
    share_dir => {
        dist   => 'root',
    },
    add_to_cleanup     => [ 'Data-Context-BEM-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Data-Context-BEM.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Context::BEM',
        },
    },
);

$builder->create_build_script();
