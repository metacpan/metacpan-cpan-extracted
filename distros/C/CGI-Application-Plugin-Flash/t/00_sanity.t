#!/usr/bin/perl
use Test::More tests => 1;
use strict;

BEGIN { use_ok('CGI::Application::Plugin::Flash'); }
diag("Testing CGI::Application::Plugin::Flash $CGI::Application::Plugin::Flash::VERSION, Perl $], $^X");
