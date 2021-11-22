#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( "App::sdview::Parser" );
use_ok( "App::sdview::Parser::Markdown" );
use_ok( "App::sdview::Parser::Pod" );

use_ok( "App::sdview::Output::Terminal" );
use_ok( "App::sdview::Output::Plain" );
use_ok( "App::sdview::Output::Pod" );
use_ok( "App::sdview::Output::Markdown" );

use_ok( "App::sdview" );

done_testing;
