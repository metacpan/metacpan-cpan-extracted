# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY );
use Test::More;

ok 1;

my $uri1  = '/app/test/days_between_dates';
my $uri2  = '/app/test/format_time';
my $data1 = GET_BODY $uri1;
my $data2 = GET_BODY $uri2;

ok t_cmp(
    $data1,
    'success',
    'testing days_between_dates() method',
  );

ok t_cmp(
    $data2,
    'success',
    'testing format_time() method',
  );

done_testing();
