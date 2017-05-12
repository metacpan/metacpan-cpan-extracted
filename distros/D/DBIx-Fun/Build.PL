#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name => 'DBIx-Fun',
    dist_version => '0.02',
    dist_author => 'Jeffrey Klein',
    dist_abstract =>'DBIx::Fun - access database stored procedures as methods',
    license => 'perl',
    requires => {
        perl => '5.8',
        DBI => '1.38',
    },
    build_requires => {
        'Test::More' => 0.01
    }
);

$build->create_build_script();

