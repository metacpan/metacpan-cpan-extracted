#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use base 'CGI::Application';
    use_ok('CGI::Application::Plugin::REST', (':all'));

}

diag(

    "Testing CGI::Application::Plugin::REST $CGI::Application::Plugin::REST::VERSION, Perl $], $^X\n",

);
