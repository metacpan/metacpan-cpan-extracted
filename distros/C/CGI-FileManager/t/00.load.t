#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;
use lib "blib/lib";


BEGIN { use_ok( 'CGI::FileManager' ); }

diag( "Testing CGI::FileManager $CGI::FileManager::VERSION" );


