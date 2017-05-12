use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::SimpleScan::Plugin::LinkCheck',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    dist_version_from   => 'lib/App/SimpleScan/Plugin/LinkCheck.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'App-SimpleScan-Plugin-LinkCheck-*' ],
);

$builder->create_build_script();
