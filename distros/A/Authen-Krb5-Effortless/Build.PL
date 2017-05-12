use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Authen::Krb5::Effortless',
    license             => 'apache',
    dist_author         => q{Adam Faris <afaris@cpan.org>},
    dist_version_from   => 'lib/Authen/Krb5/Effortless.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'         => 5.006,
        'Carp'         => 0,
        'Authen::Krb5' => 0,
        'parent'       => 0,
    },
    add_to_cleanup      => [ 'Authen-Krb5-Effortless-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
