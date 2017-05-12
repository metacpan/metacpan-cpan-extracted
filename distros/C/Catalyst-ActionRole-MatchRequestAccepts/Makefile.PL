#!/usr/bin/env perl

use strict;
use warnings FATAL =>'all';
use inc::Module::Install 1.00;
all_from 'lib/Catalyst/ActionRole/MatchRequestAccepts.pm';

requires 'Moose';
requires 'Perl6::Junction';
requires 'namespace::autoclean';
requires 'HTTP::Headers::Util';

test_requires 'Test::More' => '0.96';
test_requires 'Moose';
test_requires 'Catalyst';
test_requires 'Catalyst::Test';
test_requires 'Catalyst::Controller::ActionRole';
test_requires 'HTTP::Request::Common';

require 'maint/Makefile.PL.include'
  unless -e 'META.yml';

WriteAll;
