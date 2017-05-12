#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(:all) );
}

foreach my $method (
  qw/
    add_to_xsv
    clean_field_names
    xsv_report
    xsv_report_web
    /
)
{
  can_ok( 'main', $method );
}
