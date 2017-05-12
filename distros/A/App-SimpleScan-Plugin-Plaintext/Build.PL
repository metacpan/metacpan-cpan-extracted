use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::SimpleScan::Plugin::Plaintext',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    dist_version_from   => 'lib/App/SimpleScan/Plugin/Plaintext.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'App::SimpleScan' => 1.0,
    },
    add_to_cleanup      => [ 'App-SimpleScan-Plugin-Plaintext-*' ],
);

$builder->create_build_script();
