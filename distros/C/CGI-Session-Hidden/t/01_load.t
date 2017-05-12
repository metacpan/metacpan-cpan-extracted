#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use_ok( 'CGI::Session::Hidden' );
use_ok( 'CGI::Session::Driver::hidden' );
