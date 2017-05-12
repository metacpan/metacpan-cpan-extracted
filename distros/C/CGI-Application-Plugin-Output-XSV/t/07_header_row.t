#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

my $report;

# test creating header list from values
# passing list of hashes
$report= xsv_report({
  fields    => [ qw(foo bar baz) ],
  values    => [ { foo => 1, bar => 2, baz => 3 }, ],
});

my $first_line= (split "\n" => $report)[0];

is( $first_line, "Foo,Bar,Baz", "header list created automatically (hashes)" );

# test use of own headers
$report= xsv_report({
  headers   => [ qw(fOO bAR bAZ) ],
  fields    => [ qw(foo bar baz) ],
  values    => [ { foo => 1, bar => 2, baz => 3 }, ],
});

$first_line= (split "\n" => $report)[0];
is( $first_line, "fOO,bAR,bAZ", "provided header list is used (hashes)" );

# passing list of lists
# header list is created from values
$report= xsv_report({
  values    => [ [ 1, 2, 3 ], ],
});

$first_line= (split "\n" => $report)[0];
is( $first_line, "0,1,2", "header list created automatically (arrays)" );

$report= xsv_report({
  headers   => [ qw(fOO bAR bAZ) ],
  values    => [ [ 1, 2, 3 ], ],
});

$first_line= (split "\n" => $report)[0];
is( $first_line, "fOO,bAR,bAZ", "provided header list is used (arrays)" );

$report= xsv_report({
  values          => [ [ 1, 2, 3 ], ],
  include_headers => 0,
});

$first_line= (split "\n" => $report)[0];
is( $first_line, "1,2,3", "header list is suppressed" );

