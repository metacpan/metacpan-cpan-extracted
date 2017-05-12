#!/usr/bin/perl -w

use strict;
use Test::More tests => 20;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::Lib::Expat') }

my $lib_dir = catdir 't', 'testlib';
my $inc_dir = catdir 't', 'testinc';

ok( my $expat = App::Info::Lib::Expat->new(
    search_lib_dirs => $lib_dir,
    search_inc_dirs => $inc_dir,
), "Got Object");
isa_ok($expat, 'App::Info::Lib::Expat');
isa_ok($expat, 'App::Info::Lib');
isa_ok($expat, 'App::Info');
ok( $expat->name, "Got name" );
is( $expat->key_name, 'Expat', "Check key name" );

ok( $expat->installed, "libexpat is installed" );
is( $expat->name, "Expat", "Get name" );
is( $expat->version, "1.95.8", "Test Version" );
is( $expat->major_version, '1', "Test major version" );
is( $expat->minor_version, '95', "Test minor version" );
is( $expat->patch_version, '8', "Test patch version" );
is( $expat->lib_dir, $lib_dir, "Test lib dir" );
ok( ! defined $expat->bin_dir, "Test bin dir" );
ok( ! defined $expat->executable, "Test executable" );
is( $expat->so_lib_dir, $lib_dir, "Test so lib dir" );
is( $expat->inc_dir, $inc_dir, "Test inc dir" );
is( $expat->home_url, 'http://expat.sourceforge.net/', "Get home URL" );
is( $expat->download_url, 'http://sourceforge.net/projects/expat/',
    "Get download URL" );
