#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "App::MatrixTool" );

use_ok( "App::MatrixTool::HTTPClient" );
use_ok( "App::MatrixTool::ServerIdStore" );

use_ok( "App::MatrixTool::Command::client" );
use_ok( "App::MatrixTool::Command::client::json" );
use_ok( "App::MatrixTool::Command::client::list_rooms" );
use_ok( "App::MatrixTool::Command::client::login" );
use_ok( "App::MatrixTool::Command::client::sync" );
use_ok( "App::MatrixTool::Command::client::upload" );
use_ok( "App::MatrixTool::Command::directory" );
use_ok( "App::MatrixTool::Command::notary" );
use_ok( "App::MatrixTool::Command::resolve" );
use_ok( "App::MatrixTool::Command::server_key" );

done_testing;
