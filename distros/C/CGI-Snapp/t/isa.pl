#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Snapp;

use Test::More;

# ------------------------------------------------

my($count) = 0;

isa_ok(CGI::Snapp -> new(send_output => 0), 'CGI::Snapp'); $count++;

done_testing($count);
