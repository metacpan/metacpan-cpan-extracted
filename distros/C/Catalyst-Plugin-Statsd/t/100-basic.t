#!perl

use Test::Most;

use lib 't/lib';

use Catalyst::Test 'StatsApp';

my $res = request('/');

{
    no warnings 'once';

    cmp_deeply \@MockStatsd::Data,
      bag(
        re('^catalyst\.response\.time:\d+\|ms$'),
        re('^catalyst\.stats\.root\.base\.time:\d+\|ms$'),
      ),
      'expected metrics'
      or diag( explain \@MockStatsd::Data );

}

done_testing;
