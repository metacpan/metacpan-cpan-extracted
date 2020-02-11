#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log );
use Data::Dumper;
use Test::More;
use Test::Warnings;

#
# To activate debugging, uncomment the following
#
#use App::CELL::Test::LogToFile;
#$log->init( debug_mode => 1 );

my $status;
$log->init( ident => 'CELLtest' );
$log->info( "-------------------------------------------------" );
$log->info( "---             034-status-dump.t             ---" );
$log->info( "-------------------------------------------------" );

$log->info("*****");
$log->info("***** TESTING \$CELL->load" );
is( $CELL->loaded, 0, "CELL not loaded yet" );
$status = $CELL->load( verbose => 1 );
is( $CELL->loaded, 'SHARE', "CELL sharedir loaded" );
# load routine will generate a warning because no sitedir specified,
# but App::CELL's own sharedir will be loaded
is( $status->level, 'WARN' );

$log->info("*****");
$log->info("***** TESTING \$status->dump without args" );
$status = $CELL->status_warn( 'CELL_TEST_MESSAGE' );
# diag( Dumper $status );
$status->dump( 'to' => 'log' );
my $dumped_string = $status->dump();
is( $dumped_string, "WARN: (CELL_TEST_MESSAGE) This is a test message", "Message without args logged correctly to string" );
$status->dump( fd => \*STDOUT );

$log->info("*****");
$log->info("***** TESTING \$status->dump with args" );
$status = $CELL->status_warn( 'CELL_UNKNOWN_MESSAGE_CODE', args => [ 'bad news bears' ] );
# diag( Dumper $status );
$status->dump( 'to' => 'log' );
$dumped_string = $status->dump();
is( $dumped_string, "WARN: (CELL_UNKNOWN_MESSAGE_CODE) Unknown system message ->bad news bears<-", "Message with args logged correctly to string" );
$status->dump( fd => \*STDOUT );

done_testing;
