#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "App::MatrixClient" );
use_ok( "App::MatrixClient::Matrix" );
use_ok( "App::MatrixClient::RoomTab" );

done_testing;
