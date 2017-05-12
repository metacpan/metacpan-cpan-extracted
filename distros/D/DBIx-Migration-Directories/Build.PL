#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use lib 'lib';
use DBIx::Migration::Directories::Build;

my $build = DBIx::Migration::Directories::Build->new(
    module_name         => 'DBIx::Migration::Directories',
    license             => 'perl',
    requires            => {
        'DBIx::Transaction'         => '0.005',
        'Pod::Usage'                => '1',
        'DBI'                       => '1.41',
        'File::Basename::Object'    => '0.01',
    },
    build_requires      => {
        'Data::Dumper'      => '2.10',
        'Module::Build'     => '0.27_03',
    },
    create_makefile_pl  => 'passthrough',
    auto_features       => {
        Pg      => {
            description => 'PostgreSQL Support',
            requires    => {
                'DBD::Pg'       =>  '1.31'
            }
        },
        mysql   => {
            description => 'MySQL Support',
            requires    => {
                'DBD::mysql'    =>  '1.1211'
            }
        },
        SQLite2  => {
            description => 'SQLite2 Support',
            required    => {
                'DBD::SQLite2'   =>  '0.33',
            }
        },
    },
    script_files        => [ 'bin/migrate-database-schema' ],
    add_to_cleanup      => [ 'test_db' ],
);

$build->autotest_with({
    'DBD::SQLite2'  =>  '0.33'
});
    
my %test_opts = (
    Pg  =>  '',
    mysql => '',
);
    
if($build->feature('Pg')) {
    $test_opts{Pg} =
        $build->y_n("Do you want to run the PostgreSQL tests? (y/n)", "n");
}

if($test_opts{Pg}) {
    my $user = scalar getpwuid($<);
    $test_opts{Pg_host} = $build->prompt(
        " Postgres server hostname (leave blank to use local socket):"
    );
    
    if($test_opts{Pg_host}) {
        $test_opts{Pg_port} = $build->prompt(
            " Postgres server port (leave blank to use default):"
        );
    }
    
    $test_opts{Pg_db} = $build->prompt(" Name of database to use", $user);
    $test_opts{Pg_user} = $build->prompt(
        " User to connect to the database as", $user
    );
    $test_opts{Pg_pass} = $build->prompt(
        " Password to connect to the database with:"
    );
}

if($build->feature('mysql')) {
    $test_opts{mysql} = $build->y_n(
        "Do you want to run the MySQL tests? (y/n)", "n"
    );
}

if($test_opts{mysql}) {
    my $user = scalar getpwuid($<);
    $test_opts{mysql_host} = $build->prompt(
        " MySQL server hostname (leave blank to use local socket):"
    );
    if($test_opts{mysql_host}) {
        $test_opts{mysql_port} = $build->prompt(
            " MySQL server port (leave blank to use default):"
        );
    }
    $test_opts{mysql_db} = $build->prompt(" Name of database to use", 'test');
    $test_opts{mysql_user} = $build->prompt(
        " User to connect to the database as", $user
    );
    $test_opts{mysql_pass} = $build->prompt(
        " Password to connect to the database with:"
    );
}

if($build->feature('SQLite2')) {
    $test_opts{SQLite2} = $build->y_n(
        "Do you want to run the SQLite2 tests? (y/n)", "y"
    );
}

$build->create_build_script;

use Data::Dumper;
my $tfh;
open($tfh, '>', '_build/test_opts.ph') or die "saving test options failed: $!";
print $tfh (Data::Dumper->Dump([\%test_opts], ['*test_opts']));
close($tfh);
