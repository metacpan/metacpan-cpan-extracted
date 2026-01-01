#!/usr/bin/env perl
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'DBIx::Auto::Migrate',
    license       => 'perl_5',
    dist_author   => 'Sergio Iglesias <sergioxz@cpan.org>',
    dist_abstract =>
'DBIx::Auto::Migrate - Wrap your database connections and automatically apply db migrations',
    requires => {
        'perl' => '5.16.3',
        'DBI'  => 0,
    },
    test_requires => {
        'Test::Exception'  => 0,
        'Test::PostgreSQL' => 0,
        'Test::More'       => 0,
        'DBD::Pg'          => 0,
        'Test::MockModule' => 0,
        'Test::MockObject' => 0,
    },
    meta_merge => {
        resources => {
            bugtracker =>
              'https://github.com/sergiotarxz/Perl-DBIx-Auto-Migrate/issues',
            repository =>
              'https://github.com/sergiotarxz/Perl-DBIx-Auto-Migrate',
        }
    },
);
$build->create_build_script;
