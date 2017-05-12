use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::MirrorTracer',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/Acme/MirrorTracer.pm',
    requires          => {
        'Test::More' => 0,
    },
    add_to_cleanup => ['Acme-MirrorTracer-*'],
);

$builder->create_build_script();
