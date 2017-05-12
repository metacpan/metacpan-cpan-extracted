use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Token',
    license             => 'perl',
    dist_author         => 'Scott Penrose <scott@cpan.org>',
    dist_version_from   => 'lib/Data/Token.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Data::UUID' => 0,
        'Digest::SHA' => 0,
    },
    add_to_cleanup      => [ 'Data-Token-*' ],
);

$builder->create_build_script();
