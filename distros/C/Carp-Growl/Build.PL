use strict;
use warnings;
use Module::Build qw/0.11/;

my $builder = Module::Build->new(
    module_name       => 'Carp::Growl',
    license           => 'artistic',
    dist_author       => 'kpee <kpee.cpanx@gmail.com>',
    dist_version_from => 'lib/Carp/Growl.pm',
    requires          => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'       => 0,
        'Growl::Any' => 0,
    },
    add_to_cleanup => ['Carp-Growl-*'],
);

$builder->create_build_script();
