#!perl -T
use 5.012;
use strict;
use warnings;
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Test qw( cmp_arrays );
use File::Spec;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("-------------------------------------------------------- ");
$log->info("---                   003-test.t                     ---");
$log->info("-------------------------------------------------------- ");

$status = App::CELL::Test::mktmpdir();
ok( $status->ok, "mktmpdir status OK" );
my $tmpdir = $status->payload;
ok( -d $tmpdir, "Test directory is present" );

$status = App::CELL::Test::touch_files( $tmpdir, 'foo', 'bar', 'baz' );
is( $status, 3, "touch_files returned right number" );

$status = App::CELL::Test::cleartmpdir();
ok( $status->ok, "cleartmpdir status OK" );
ok( ! -e $tmpdir, "Test directory really gone" );

$status = -d $tmpdir;
ok( ! $status, "Test directory is really gone" );

my $booltrue = cmp_arrays( [ 0, 1, 2 ], [ 0, 1, 2 ] );
ok( $booltrue, "cmp_arrays works on identical arrays" );

my $boolfalse = cmp_arrays( [ 0, 1, 2 ], [ 'foo', 'bar', 'baz' ] );
ok( ! $boolfalse, "cmp_arrays works on different arrays" );

$booltrue = cmp_arrays( [], [] );
ok( $booltrue, "cmp_arrays works on two empty arrays" );

$boolfalse = cmp_arrays( [], [ 'foo' ] );
ok( ! $boolfalse, "cmp_arrays works on one empty and one non-empty array" );

$booltrue = cmp_arrays( [ 1, 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1 ] );
ok( $booltrue, "cmp_arrays works on two identical arrays of repeating ones" );

#$boolfalse = cmp_arrays( [ 1, 1, 1, 1 ], [ 1, 1, 1, 1, 1 ] );
#is( $boolfalse, 0, "cmp_arrays works on two different arrays of repeating ones" );

done_testing;
