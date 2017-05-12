#! /usr/bin/perl

use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'DB2::db',
     license => 'perl',
     requires => {
         DBD::DB2 => '0.78',
         Test::NoWarnings => 0,
         Test::More => 0.88,
     },
    );

$build->create_build_script();

