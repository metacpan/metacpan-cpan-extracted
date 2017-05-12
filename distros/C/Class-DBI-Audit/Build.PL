use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::DBI::Audit',
    license           => 'perl',
    dist_author       => 'Brian Duggan <bduggan@matatu.org>',
    dist_version_from => 'lib/Class/DBI/Audit.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'Class::DBI' => 0,
        'mixin'      => 0,
        'SQL::Abstract' => 0,
        'DBD::SQLite' => '== 1.12',
    },
    add_to_cleanup => ['Class-DBI-Audit-*'],
);

$builder->create_build_script();

