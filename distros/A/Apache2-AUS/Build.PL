#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use lib 'lib';
use Module::Build;

our %opts = (
    module_name         =>  'Apache2::AUS',
    license             =>  'perl',
    requires            =>  {
        'DBIx::Migration::Directories'  =>      '0.01',
        'mod_perl2'                     =>      '2.000001',
        'Schema::RDBMS::AUS'            =>      '0.03',
        'Apache2::Request'              =>      '2.06',
    },
    build_requires      =>  {
        'Module::Build'                 =>      '0.27_03',
        'Apache::Test'                  =>      '0',
        'Apache::TestMB'                =>      '0',
        'Schema::RDBMS::AUS'            =>      '0.03',
        'DBIx::Migration::Directories'  =>      '0.05',
        'mod_perl2'                     =>      '2.000001',
        'DBIx::Transaction'             =>      '0.007',
    },
    create_makefile_pl  =>  'passthrough',
);

eval { require Apache::TestMB; };

my $build;

if($@) {
    $build = Module::Build->new(%opts, installdirs => {});
    print <<"EOT";
*** Apache::TestMB is required to build this module!

    This is supplied by the mod_perl2 package.
    Once you have installed this package, you may have to run "Build.PL"
    again. If you are installing from CPAN, you may need to quit and
    re-enter your CPAN shell.

EOT
    $build->prompt("Press enter to continue", ".");
} else {
    $build = Apache::TestMB->new(%opts);
}

print qq{Example DSN: "DBI:mysql:database=test"\n};
if($build->notes(DBI_DSN => $build->prompt(
    "What DSN should we use for database tests? (Enter '0' to skip DB tests)",
    exists $ENV{DBI_DSN} ? $ENV{DBI_DSN} : 0
))) {
    $build->notes(DBI_USER => $build->prompt(
        "Username for the database connection:", $ENV{DBI_USER}
    ));
    $build->notes(DBI_PASS => $build->prompt(
        "Password for the database connection:", $ENV{DBI_PASS}
    ));
} else {
    $build->notes(DBI_USER => undef);
    $build->notes(DBI_PASS => undef);
}

$build->create_build_script;
