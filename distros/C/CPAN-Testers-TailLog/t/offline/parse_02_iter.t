use strict;
use warnings;

use Test::More;
use lib 't/lib';

use HTTP::Tiny::Mock;
use CPAN::Testers::TailLog;
my $tail =
  CPAN::Testers::TailLog->new(
    _ua => HTTP::Tiny::Mock->new('t/files/02-log.txt') );

my $iter = $tail->get_iter();

cmp_ok( ref $iter, 'eq', 'CODE', 'CodeRef returned' );

my $index = -1;    # 0-index

while ( my $result = $iter->() ) {
    $index++;      # -1 -> 0 first time
    my $cat_no = $index + 1;
    ok(
        defined $result->submitted,
"Item $index( cat -n record | grep $cat_no ) has defined submission time"
    ) or diag explain $result;
}

cmp_ok( $index + 1, '>',  0,    'Some results' );
cmp_ok( $index + 1, '==', 1000, '1000 results parsed' );

done_testing;

