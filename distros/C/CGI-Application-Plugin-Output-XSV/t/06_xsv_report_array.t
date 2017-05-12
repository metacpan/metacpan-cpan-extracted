#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

my $report;

# passing list of lists
# header list is created from values
$report= xsv_report({
  include_headers => 0,
  values    => [
    [ 1, 2, 3 ],
    [ 4, 5, 6 ],
  ],
});

is( $report, "1,2,3\n4,5,6\n",
    "report output matches (no headers)" );

$report= xsv_report({
  headers   => [ qw(fOO bAR bAZ) ],
  values    => [ [ 1, 2, 3 ], ],
});

is( $report, "fOO,bAR,bAZ\n1,2,3\n",
    "report output matches (specify headers)" );

# specify field order
$report= xsv_report({
  headers   => [ qw(two three one) ],
  fields    => [ 1, 2, 0 ],
  values    => [ [ 1, 2, 3 ], ],
});

is( $report, "two,three,one\n2,3,1\n",
    "report output matches (specify field order)" );

$report= xsv_report({
  fields    => [ qw(foo bar baz) ],
  values    => [ ],
});

is( $report, "Foo,Bar,Baz\n", "report output (empty list) matches" );
