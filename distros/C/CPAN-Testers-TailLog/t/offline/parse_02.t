use strict;
use warnings;

use Test::More;
use lib 't/lib';

use HTTP::Tiny::Mock;
use CPAN::Testers::TailLog;
my $tail =
  CPAN::Testers::TailLog->new(
    _ua => HTTP::Tiny::Mock->new('t/files/02-log.txt') );

my $results = $tail->get_all();

cmp_ok( ref $results,       'eq', 'ARRAY', 'ArrayRef returned' );
cmp_ok( scalar @{$results}, '>',  0,       'Some results' );
cmp_ok( scalar @{$results}, '==', 1000,    '1000 results parsed' );

for my $result ( 0 .. $#{$results} ) {
    my $cat_no = $result + 2;
    ok(
        defined $results->[$result]->submitted,
"Item $result (cat -n record | grep $cat_no) has defined submission time"
      )
      or diag explain [
        $results->[ $result - 1 ],
        $results->[$result],
        $results->[ $result + 1 ],
      ];
}

done_testing;

