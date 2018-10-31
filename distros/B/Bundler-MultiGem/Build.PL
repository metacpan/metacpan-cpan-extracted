use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bundler::MultiGem',
    license             => 'mit',
    dist_author         => q{Mauro Berlanda <kupta@cpan.org>},
    dist_version_from   => 'lib/Bundler/MultiGem.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'      => '0',
        'Test::Deep'      => '0',
        'Test::Exception' => '0',
    },
    requires => {
        'App::Cmd'        => '0.331',
        'common::sense'   => '3',
        'Cwd'             => '3',
        'File::Find'      => '1',
        'File::Path'      => '2',
        'File::Spec'      => '3',
        'File::Spec::Functions' => '3',
        'Hash::Merge'     => '0.3',
        'Storable'        => '2.50',
        'YAML::Tiny'      => '1.7'
    },
    add_to_cleanup     => [ 'Bundler-MultiGem-*' ],
);

$builder->create_build_script();
