#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);

my $ret = system( @cmdroot, qw(-t User pull) );
ok( $ret == 0, "run pull with -t User" );

$ret = system(qw(diff -ur table t/15-pull-restricted.d/table));
ok( $ret == 0, "check pull sql" );

$ret = system(qw(diff -ur procedure t/15-pull-restricted.d/procedure));
ok( $ret == 0, "check pull sql" );

clear_directories();

$ret = system( @cmdroot, qw(-t U% pull) );
ok( $ret == 0, "run pull with -t U%" );

$ret = system(qw(diff -ur table t/15-pull-restricted.d/table));
ok( $ret == 0, "check pull sql" );

$ret = system(qw(diff -ur procedure t/15-pull-restricted.d/procedure));
ok( $ret == 0, "check pull sql" );

exit 0;
