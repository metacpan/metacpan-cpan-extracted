#!/usr/bin/perl

# $Id$

use strict;
use FindBin;
use Test::More tests => 1;

use CGI::Session;
use CGI::Session::Driver::aggregator::Drivers;

my $dir = "$FindBin::RealBin/tmp";
mkdir $dir;
mkdir "$dir/_aggregator";

my $drivers = CGI::Session::Driver::aggregator::Drivers->new;
$drivers->add('file', { Directory => $dir });
$drivers->add('file', { Directory => "$dir/_aggregator" });

my $session = CGI::Session->new('driver:aggregator', undef, { Drivers => $drivers });
$session->param(a => 'b');
$session->flush();
is('b', $session->param('a'), 'param');
