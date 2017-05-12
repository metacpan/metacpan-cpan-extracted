#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

my $report;

# passing list of hashes
# header list is created from provided fields
$report= xsv_report({
  fields    => [ qw(foo bar baz) ],
  values    => [ { foo => 1, bar => 2, baz => 3 }, ],
});

is( $report, "Foo,Bar,Baz\n1,2,3\n", "report output (hash input) matches" );

$report= xsv_report({
  headers   => [ qw(fOO bAR bAZ) ],
  fields    => [ qw(foo bar baz) ],
  values    => [ { foo => 1, bar => 2, baz => 3 }, ],
});

is( $report, "fOO,bAR,bAZ\n1,2,3\n", "report output (hash input) matches" );

$report= xsv_report({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
  fields          => [ qw(first_name last_name phone) ],
  headers_cb      => sub {
    my @h= @{ +shift };
    s/_name$// foreach @h;
    return \@h;
  },
});

is( $report, "first,last,phone\nJack,Tors,555-1212\nFrank,Rizzo,555-1515\n",
    "report output (custom header cb) matches" );

$report= xsv_report({
  values    => [ { foo => 1, bar => 2, baz => 3 }, ],
});

ok( $report, "defaults generated for fields when not provided" );

$report= xsv_report({
  fields    => [ qw(foo bar baz) ],
  values    => [ ],
});

is( $report, "Foo,Bar,Baz\n", "report output (empty list) matches" );
