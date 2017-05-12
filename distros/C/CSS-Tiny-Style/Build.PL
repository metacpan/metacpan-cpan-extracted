use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CSS::Tiny::Style',
    license             => 'perl',
    dist_author         => 'Simone Cesano <scesano@cpan.org>',
    dist_version_from   => 'lib/CSS/Tiny/Style.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'CSS-Tiny-Style-*' ],
);

$builder->create_build_script();
