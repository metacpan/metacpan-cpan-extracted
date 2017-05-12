#!/usr/bin/perl -Ilib/ -I../lib/

use strict;
use warnings;


use Test::More qw! no_plan !;


BEGIN {use_ok("CGI::Session")}
require_ok("CGI::Session");

BEGIN {use_ok("CGI::Session::Driver::redis")}
require_ok("CGI::Session::Driver::redis");
