#!/usr/bin/perl -w

use strict;
use Test::More tests => 19;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::Lib::Iconv') }

my $ext = $^O eq 'MSWin32' ? '.bat' : '';
my $lib_dir = catdir 't', 'testlib';
my $inc_dir = catdir 't', 'testinc';
my $bin_dir = catdir 't', 'scripts';
$bin_dir = catdir 't', 'bin' unless -d $bin_dir;
my $executable = catfile $bin_dir, "iconv$ext";

ok( my $iconv = App::Info::Lib::Iconv->new(
    search_lib_dirs => $lib_dir,
    search_exe_names => ["iconv$ext"],
    search_inc_dirs => $inc_dir,
    search_bin_dirs => $bin_dir,
), "Got Object");
isa_ok($iconv, 'App::Info::Lib::Iconv');
isa_ok($iconv, 'App::Info');
is( $iconv->name, 'libiconv', "Check name" );
is( $iconv->key_name, 'libiconv', "Check key name" );

ok( $iconv->installed, "libiconv is installed" );
is( $iconv->name, "libiconv", "Get name" );
is( $iconv->version, "1.9", "Test Version" );
is( $iconv->major_version, '1', "Test major version" );
is( $iconv->minor_version, '9', "Test minor version" );
ok( ! defined $iconv->patch_version, "Test patch version" );
is( $iconv->lib_dir, $lib_dir, "Test lib dir" );
is( $iconv->bin_dir, $bin_dir, "Test bin dir" );
is( $iconv->executable, $executable, "Test executable" );
is( $iconv->so_lib_dir, $lib_dir, "Test so lib dir" );
is( $iconv->inc_dir, $inc_dir, "Test inc dir" );
is( $iconv->home_url, 'http://www.gnu.org/software/libiconv/', "Get home URL" );
is( $iconv->download_url, 'ftp://ftp.gnu.org/pub/gnu/libiconv/',
    "Get download URL" );
