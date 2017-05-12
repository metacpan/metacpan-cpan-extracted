use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::TryAgain',
    license             => 'perl',
    dist_author         => q{Brian Duggan <bduggan@matatu.org>},
    dist_version_from   => 'lib/DBIx/TryAgain.pm',
    abstract            => "If at first you don't succeed, try, try again.",
    dist_abstract       => "If at first you don't succeed, try, try again.",
    build_requires => {
        'Test::More' => 0,
        'DBI' => 0,
        'DBD::SQLite' => '1.37',
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'DBIx-TryAgain-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
