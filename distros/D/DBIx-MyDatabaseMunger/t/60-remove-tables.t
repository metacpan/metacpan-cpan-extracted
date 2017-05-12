#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;

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

unlink "table/Service.pm";

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push without --remove=any" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/60-remove-tables.noremove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/60-remove-tables.noremove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

unlink "table/Service.sql";
unlink "view/ServiceWithOwner.sql";

$ret = system( @cmdroot, "--remove=any", "push" );
ok( $ret == 0, "push with --remove=any" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/60-remove-tables.yesremove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/60-remove-tables.yesremove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );


exit 0;
