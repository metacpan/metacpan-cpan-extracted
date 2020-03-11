#!perl

use Test::Most;

use lib 't/lib';

use Catalyst::Test 'StatsApp';

my $log    = StatsApp->log;

my $res = request('/');

{
    no warnings 'once';

    cmp_deeply \@MockStatsd::Data,
      bag(
        re('^catalyst\.response\.time:\d+\|ms$'),
        re('^catalyst\.stats\.root\.base\.time:\d+\|ms$'),
        re('^catalyst\.stats\.rootx\.foo-bar_baz\.time:\d+\|ms$'),
        re('^catalyst.sessionid:\d+\|s$'),
      ),
      'expected metrics'
      or diag( explain \@MockStatsd::Data );

}

cmp_deeply $log->msgs, [
    superhashof(
        {
            level   => 'debug',
            message => 'Statistics enabled',
        }
    ),
    superhashof(
        {
            level   => 'info',
            message => re(
                '^Request took \d\.\d+s \(\d+\.\d+/s\)\n.+\n\| Action +\| Time'
            ),

        }
    ),
  ],
  'logged output';

done_testing;
