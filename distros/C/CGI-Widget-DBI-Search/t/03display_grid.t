#!/usr/bin/perl

use strict;

use Test::Unit::HarnessUnit;
my $r = Test::Unit::HarnessUnit->new();
$r->start('CGI::Widget::DBI::Search::Display::TEST::Grid');
