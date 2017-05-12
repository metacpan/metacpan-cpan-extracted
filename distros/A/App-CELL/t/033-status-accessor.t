#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log );
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------- ");
$log->info("---          033-status-accessor.t            ---");
$log->info("------------------------------------------------- ");

$status = $CELL->load( verbose => 1 );
# load routine will generate a warning because no sitedir specified,
# but App::CELL's own sharedir will be loaded
is( $status->level, 'WARN' );

$status = $CELL->status_ok( 'CELL_TEST_MESSAGE', args => [ 1 ] );
is( $status->code, 'CELL_TEST_MESSAGE' );

# use accessors to change properties
$status->level( 'CRIT' );
$status->code( 'SOMETHING_ELSE' );
$status->args( [ 'FOO', 'BAR' ] );
is( $status->level, 'CRIT' );
is( $status->code, 'SOMETHING_ELSE' );
is_deeply( $status->args, [ 'FOO', 'BAR' ] );

done_testing;
