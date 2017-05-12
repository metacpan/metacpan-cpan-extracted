#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );
}

sub plus_one {
  my( $row, $fields )= @_;

  return [ map { $_ + 1 } @$row{@$fields} ];
}

my $report;

# test creating header list from values
# passing list of hashes
$report= xsv_report({
  fields     => [ qw(foo bar baz) ],
  values     => [ { foo => 1, bar => 2, baz => 3 }, ],
  row_filter => \&plus_one,
});

is( $report, "Foo,Bar,Baz\n2,3,4\n", "rows are filtered using user callback" );

sub some_other_data {
  return [ "Jolly",42 ];
}

$report= xsv_report({
  values          => [ [ 1, 2, 3 ], ],
  row_filter      => \&some_other_data,
  include_headers => 0,
});

is( $report, "Jolly,42\n", "rows are filtered using user callback" );

sub uppercase {
  my( $row, $fields )= @_;

  return [ map { uc } @$row{@$fields} ];
};

$report= xsv_report({
  fields          => [ qw(first second third) ],
  values          => [ { first => 'foo', second => 'bar', third => 'baz' }, ],
  row_filter      => \&uppercase,
  include_headers => 0,
});

is( $report, "FOO,BAR,BAZ\n", "rows are filtered using user callback" );

# row filter with iterator -- contrived to use fields parameter
# (can't think of a typical example where fields parameter would be used)
my @words = ( [ qw(foo bar baz) ], [ qw(qux quo quux) ] );

$report= xsv_report({
  fields     => [ 1..3 ],
  iterator   => sub {
    while ( @words ) {
      return shift @words;
    }
  },
  row_filter => sub {
    my ($row_ref, $fields_ref) = @_;

    foreach my $w ( @{$row_ref} ) {
      $w = join(":", @{$fields_ref}, scalar reverse $w);
    }

    return $row_ref;
  },
});

is( $report,
    "1,2,3\n1:2:3:oof,1:2:3:rab,1:2:3:zab\n1:2:3:xuq,1:2:3:ouq,1:2:3:xuuq\n",
    "rows are filtered using user callback" );

# row filter with iterator
my @nums = (1..3);
$report= xsv_report({
  include_headers => 0,
  iterator   => sub { while ( @nums ) { return [ shift @nums ] } },
  row_filter => sub { return [ map { $_ + 1 } @{$_[0]} ] },
});

is( $report, "2\n3\n4\n", "rows are filtered using user callback" );

