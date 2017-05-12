#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log );
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use Scalar::Util qw( blessed );
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("-------------------------------------------------- ");
$log->info("---          032-status-expurgate.t            ---");
$log->info("-------------------------------------------------- ");

$status = $CELL->load( verbose => 1 );
# load routine will generate a warning because no sitedir specified,
# but App::CELL's own sharedir will be loaded
is( $status->level, 'WARN' );

$status = $CELL->status_ok( 'CELL_TEST_MESSAGE' );
ok( blessed $status );

my $es = $status->expurgate;
#diag( "Expurgated version: " . Dumper( $es ) );
ok( ! blessed $es );

done_testing;
