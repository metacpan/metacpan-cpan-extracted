use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::DBI::Plugin::AutoUntaint',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Class/DBI/Plugin/AutoUntaint.pm',
    requires => {
        'Test::More' => 0,
        'Class::DBI::Plugin::Type' => 0,
        'Class::DBI::FromCGI' => 0,
    },
    add_to_cleanup      => [ 'Class-DBI-Plugin-AutoUntaint-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
