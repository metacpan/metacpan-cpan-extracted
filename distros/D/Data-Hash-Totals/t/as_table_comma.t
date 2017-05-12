#!perl -T

use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Hash::Totals', qw( as_table ) );
}

my %fave_stooge_votes = (
    Moe => 3104,
    Larry => 123456789,
    Curly => 97,
    Shemp => 3,
);

my @lines = as_table( \%fave_stooge_votes, comma=>1 );
my @expected = <DATA>;
is_deeply( \@lines, \@expected );

__DATA__
123,456,789 Larry
      3,104 Moe
         97 Curly
          3 Shemp
