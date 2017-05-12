#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);
my $ret;

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

$ret = system( @cmdroot, "-t", "Service", "make-archive" );
ok( $ret == 0, "Make archive table for Service" );

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push archive table stuff" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/30-make-archive.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/30-make-archive.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/30-make-archive.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

exit 0;
