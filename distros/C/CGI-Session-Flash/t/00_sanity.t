#!/usr/bin/perl
use Test::More tests => 1;
use strict;

BEGIN { use_ok('CGI::Session::Flash'); }
diag("Testing CGI::Session::Flash $CGI::Session::Flash::VERSION, Perl $], $^X");
