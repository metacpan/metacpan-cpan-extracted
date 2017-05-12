#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);

my $ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

$ret = system(qw(diff -ur table t/10-pull.d/table));
ok( $ret == 0, "check table sql" );

$ret = system(qw(diff -ur procedure t/10-pull.d/procedure));
ok( $ret == 0, "check procedure sql" );

$ret = system(qw(diff -ur view t/10-pull.d/view));
ok( $ret == 0, "check view sql" );

exit 0;
