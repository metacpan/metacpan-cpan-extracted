#!/usr/bin/perl -w

use strict;
use Test::More tests => 21;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::RDBMS::PostgreSQL') }

my $ext = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir = catdir 't', 'bin' unless -d $bin_dir;
my %exes = (
    map { $_ => catfile $bin_dir, "$_$ext" }
      qw(postgres mycreatedb)
);

ok( my $pg = App::Info::RDBMS::PostgreSQL->new(
    search_bin_dirs => $bin_dir,
    search_exe_names => "pg_config$ext",
    search_createdb_names => "mycreatedb$ext",
    search_postgres_names => "postgres$ext",
), "Got Object");

isa_ok($pg, 'App::Info::RDBMS::PostgreSQL');
isa_ok($pg, 'App::Info');
is( $pg->key_name, 'PostgreSQL', "Check key name" );

ok( $pg->installed, "PostgreSQL is installed" );
is( $pg->name, "PostgreSQL", "Get name" );
is( $pg->version, "8.0.0", "Test Version" );
is( $pg->major_version, '8', "Test major version" );
is( $pg->minor_version, '0', "Test minor version" );
is( $pg->patch_version, '0', "Test patch version" );
is( $pg->lib_dir, 't/testlib', "Test lib dir" );
is( $pg->executable, $exes{postgres}, "Test executable" );
is( $pg->postgres, $exes{postgres}, "Test postgres" );
is( $pg->createdb, $exes{mycreatedb}, "Test createdb" );
is( $pg->bin_dir, $bin_dir, "Test bin dir" );
is( $pg->so_lib_dir, 't/testlib', "Test so lib dir" );
is( $pg->inc_dir, "t/testinc", "Test inc dir" );
is( $pg->configure, '', "Test configure" );
is( $pg->home_url, 'http://www.postgresql.org/', "Get home URL" );
is( $pg->download_url, 'http://www.postgresql.org/mirrors-ftp.html',
    "Get download URL" );
