use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::TemplateCMD',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/TemplateCMD.pm',
    requires          => {
        'perl'               => 5.010,
        'version'            => 0,
        'File::ShareDir'     => '1.03',
        'Template'           => '2.14',
        'Template::Provider' => '2.94',
        'Class::Date'        => '1.001',
        'Clone'              => '0.17',
        'JSON'               => 0,
        'List::MoreUtils'    => 0,
        'Path::Tiny'         => 0,
        'Readonly'           => 0,
        'YAML'               => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    share_dir => {
        dist => [
            'templates',
        ],
    },
    add_to_cleanup     => [ 'App-TemplateCMD-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/App-TemplateCMD',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-TemplateCMD',
        },
    },
);

$builder->create_build_script();
