#!perl

#
# t/004-debug.t
#
# The purpose of this unit test is to demonstrate how the unit tests can be
# used for debugging (not to test debugging)
#

use 5.012;
use strict;
use warnings;
use App::CELL::Config qw( $site );
use App::CELL::Load;
use App::CELL::Log qw( $log );
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
$log->info("---------------------------------------------------------");
$log->info("---                   004-debug.t                     ---");
$log->info("---------------------------------------------------------");

is( $site->CELL_SHAREDIR_LOADED, undef, "CELL_SHAREDIR_LOADED is undefined before load");
$status = App::CELL::Load::init( verbose => 1 );
is( $status->level, "WARN", "Load without sitedir results gives warning" );
is( $site->CELL_SHAREDIR_LOADED, 1, "CELL_SHAREDIR_LOADED is true after load");
$status = App::CELL::Status->new( level => 'NOTICE',
               code => 'CELL_TEST_MESSAGE' );
is( $status->msgobj->text, "This is a test message", "Test message was loaded" );

done_testing;
