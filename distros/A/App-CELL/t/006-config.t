#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $log $meta );
#use App::CELL::Test::LogToFile;
use Test::More;
use Test::Warnings;

delete $ENV{CELL_DEBUG_MODE};
$log->init( debug_mode => 1 );
my $status;
$log->debug("************************************ t/006-config.t");
$status = $meta->set('MY_PARAM', 42);
ok( $status->ok, "\$meta->set status OK" );
is( $meta->MY_PARAM, 42, 'MY_PARAM is 42' );
is( $meta->get_param('MY_PARAM'), 42, 'MY_PARAM is still 42' );

done_testing;
