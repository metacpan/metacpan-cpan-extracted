#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $core $site );
use App::CELL::Test qw( cmp_arrays );
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use File::ShareDir;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------------- ");
$log->info("---                   100-cell.t                    ---");
$log->info("------------------------------------------------------- ");

is_deeply( $CELL->supported_languages, [ 'en' ], 
    "Hard-coded list of supported languages consists of 'en' only" );
ok( $CELL->language_supported( 'en' ), "English is supported" );
ok( ! $CELL->language_supported( 'fr' ), "French is not supported" );

my $bool = $meta->CELL_META_SITEDIR_LOADED;
ok( ! defined($bool), "Random config param not loaded yet" );
ok( ! $CELL->loaded, "CELL doesn't think it's loaded" );
ok( ! $log->{debug_mode}, "And we're not in debug mode" );
ok( ! $CELL->sharedir, "And sharedir hasn't been loaded" );
ok( ! $CELL->sitedir, "And sitedir hasn't been loaded, either" );

# first try without pointing to site config directory -- CELL will
# configure itself from the distro's ShareDir
$status = $CELL->load(); 
is( $status->level, "WARN", "Load without sitedir gives warning" );
is( $CELL->loaded, "SHARE", "\$CELL->loaded says SHARE");

is_deeply( $site->CELL_SUPP_LANG, [ 'en' ], 
    "CELL_SUPP_LANG is set to just English" );
is_deeply( $CELL->supported_languages, $site->CELL_SUPP_LANG,
    "Two different ways of getting supported_languages list" );

my $sharedir = $site->CELL_SHAREDIR_FULLPATH; 
ok( defined( $sharedir ), "CELL_SHAREDIR_FULLPATH is defined" );

is( $sharedir, File::ShareDir::dist_dir('App-CELL'),
    "CELL_SHAREDIR_FULLPATH is properly set to the ShareDir");
is( $sharedir, $CELL->sharedir, "Sharedir accessor works" );

my $msgobj = $CELL->msg( 'CELL_TEST_MESSAGE' );
is( $msgobj->text, "This is a test message", 
    "Basic \$CELL->msg functionality");

$status = $CELL->status_crit( 'CELL_TEST_MESSAGE' );
#diag( Dumper( $status ) );
ok( $status->level eq 'CRIT' );

$status = $CELL->status_critical( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'CRITICAL' );

$status = $CELL->status_debug( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'DEBUG' );

$status = $CELL->status_emergency( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'EMERGENCY' );

$status = $CELL->status_err( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'ERR' );

$status = $CELL->status_error( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'ERROR' );

$status = $CELL->status_fatal( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'FATAL' );

$status = $CELL->status_info( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'INFO' );

$status = $CELL->status_inform( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'INFORM' );

$status = $CELL->status_not_ok( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'NOT_OK' );

$status = $CELL->status_notice( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'NOTICE' );

$status = $CELL->status_ok( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'OK' );

$status = $CELL->status_trace( 'CELL_TEST_MESSAGE' );
ok( $status->level eq 'TRACE' );

$status = $CELL->status_warn( 'The very big %s', args => [ "Bubba" ] );
is( $status->text, 'The very big Bubba', "Status constructor takes argument" );
ok( $status->level eq 'WARN' );

$status = $CELL->status_warning( 'CELL_TEST_MESSAGE', payload => "bubba");
ok( $status->level eq 'WARNING' );
ok( $status->payload eq 'bubba' );

$status = $CELL->status_ok( 'CELL_TEST_MESSAGE_WITH_ARGUMENT', args => [ 'very nice' ] );
is_deeply( $status->args, [ 'very nice' ] );

done_testing;
