#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

my $report;

my @vals = qw(one two three four five six);

# using iterator to generate values list
$report= xsv_report({
  fields    => [ qw(foo bar baz) ],
  iterator  => sub { while ( @vals ) { return [ splice @vals, 0, 3 ] } },
});

is( $report, "Foo,Bar,Baz\none,two,three\nfour,five,six\n",
             "report output (iterator) matches" );


@vals = qw(one two three);

$report= xsv_report({
  include_headers => 0,
  iterator        => sub { while ( @vals ) { return [ splice @vals, 0, 3 ] } },
});

is( $report, "one,two,three\n",
             "report output (iterator) matches" );
