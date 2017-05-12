#!/usr/bin/perl

# $Id$

use strict;

use Test::More;
use CGI::Session::Test::Default;

#require CGI::Session::Driver::aggregator;
require CGI::Session::Driver::aggregator::Drivers;

mkdir "/tmp/_cgi_session_driver_aggregator";
my $drivers = CGI::Session::Driver::aggregator::Drivers->new;
$drivers->add('file', { Directory => '/tmp' });
$drivers->add('file', { Directory => '/tmp/_cgi_session_driver_aggregator' });

my $t = CGI::Session::Test::Default->new(
    dsn => "dr:aggregator",
    args=> { Drivers => $drivers }
);

plan tests => $t->number_of_tests;
$t->run();
