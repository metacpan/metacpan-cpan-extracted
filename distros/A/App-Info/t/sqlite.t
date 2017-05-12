#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::RDBMS::SQLite') }

my $ext = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir = catdir 't', 'bin' unless -d $bin_dir;
my $lib_dir = catdir 't', 'testlib';
my $inc_dir = catdir 't', 'testinc';
my $executable = catfile $bin_dir, "sqlite3$ext";

ok( my $sqlite = App::Info::RDBMS::SQLite->new(
    search_bin_dirs  => [$bin_dir],
    search_exe_names => ["sqlite3$ext"],
    search_lib_dirs  => [$lib_dir],
    search_inc_dirs  => [$inc_dir],
), "Got Object");

isa_ok($sqlite, 'App::Info::RDBMS::SQLite');
isa_ok($sqlite, 'App::Info');
is( $sqlite->key_name, 'SQLite', "Check key name" );

ok( $sqlite->installed, "SQLite is installed" );
is( $sqlite->name, "SQLite", "Get name" );
is( $sqlite->version, "3.0.7", "Test Version" );
is( $sqlite->major_version, '3', "Test major version" );
is( $sqlite->minor_version, '0', "Test minor version" );
is( $sqlite->patch_version, '7', "Test patch version" );
is( $sqlite->lib_dir, $lib_dir, "Test lib dir" );
is( $sqlite->executable, $executable, "Test executable" );
is( $sqlite->bin_dir, $bin_dir, "Test bin dir" );
is( $sqlite->so_lib_dir, $lib_dir, "Test so lib dir" );
is( $sqlite->inc_dir, $inc_dir, "Test inc dir" );
is( $sqlite->home_url, 'http://www.sqlite.org/', "Get home URL" );
is( $sqlite->download_url, 'http://www.sqlite.org/download.html',
    "Get download URL" );
