#!perl -w
use strict;
use Test::More tests => 5;
use DBIx::PivotQuery 'pivot_list';
use Data::Dumper;

my @list = (
    { date => 'Q1', region => 'North', amount => 150 },
    { date => 'Q2', region => 'North', amount => 50 },
    { date => 'Q3', region => 'North', amount => 50 },
    { date => 'Q4', region => 'North', amount => 10 },

    { date => 'Q1', region => 'West',  amount => 100 },
    { date => 'Q3', region => 'West',  amount => 100 },
    { date => 'Q4', region => 'West',  amount => 200 },

    { date => 'Q1', region => 'East',  amount => 75 },
    { date => 'Q2', region => 'East',  amount => 75 },
    { date => 'Q3', region => 'East',  amount => 75 },
    { date => 'Q4', region => 'East',  amount => 175 },


    { date => 'Q1', region => 'South', amount => 125 },
    { date => 'Q2', region => 'South', amount => 125 },
    { date => 'Q3', region => 'South', amount => 0 },
    { date => 'Q4', region => 'South', amount => 20 },
);

my $l = pivot_list(
    rows    => ['region'],
    columns => ['date'],
    aggregate => ['amount'],
    list => \@list,
);

is_deeply $l->[0],
          [qw(region Q1 Q2 Q3 Q4)], "We find all values for the 'date' column and use them as column headers";

is_deeply [map { $_->[0]} @$l],
          [qw(region North West East South)], "We find all values for the 'region' column and use them as row headers";

# This is basically the identity transform
$l = pivot_list(
    rows    => ['region','date'],
    aggregate => ['amount'],
    list => \@list,
);

is_deeply $l->[0],
          [qw(region date), ''], "When not pivoting, we still find all column headers";

# This is basically the rotation
$l = pivot_list(
    columns   => ['region','date'],
    aggregate => ['amount'],
    list => \@list,
);

is 0+@$l, 2, "We get one looong table with one row";
is @{$l->[0]}, 15, "We get fifteen columns, because West/Q2 is missing in the input data"
    or diag Dumper $l;
