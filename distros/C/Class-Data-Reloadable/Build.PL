use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Data::Reloadable',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Class/Data/Reloadable.pm',
    requires => {
        'Test::More' => 0,
        'NEXT' => 0,
        'Class::ISA' => 0,
        'Carp' => 0,
        'Test::Exception' => 0,
        'Symbol' => 0,
        'UNIVERSAL::require' => 0,

    },
    add_to_cleanup      => [ 'Class-Data-Reloadable-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
