use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::DBI::Plugin::Backtickify',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Class/DBI/Plugin/Backtickify.pm',
    requires => {
        'Test::More' => 0,
        'Class::DBI' => 0,  # for tests
        'Class::ISA' => 0,
    },
    add_to_cleanup      => [ 'Class-DBI-Plugin-Backtickify-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
