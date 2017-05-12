#!/usr/bin/env perl
#
# This tests --remove=any with pull action.
#
use strict;
use warnings;
use Test::More tests => 9;

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

t_drop_table( 'Service' );

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull without --remove=any" );

$ret = system(qw(diff -ur table t/65-remove-tables.noremove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/65-remove-tables.noremove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system( @cmdroot, "--remove=any", "pull" );
ok( $ret == 0, "pull with --remove=any" );

$ret = system(qw(diff -ur table t/65-remove-tables.yesremove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/65-remove-tables.yesremove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

ok( ! -e "table/Service.sql", "check that table/Service.sql is removed" );

exit 0;
