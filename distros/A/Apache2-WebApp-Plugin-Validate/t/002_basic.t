# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY );
use Test::More;

ok 1;

my $uri1   = '/app/test/browser';
my $uri2   = '/app/test/currency';
my $uri3   = '/app/test/date';
my $uri4   = '/app/test/date_is_future';
my $uri5   = '/app/test/date_is_past';
my $uri6   = '/app/test/domain';
my $uri7   = '/app/test/email';
my $uri8   = '/app/test/integer';
my $uri9   = '/app/test/html';
my $uri10  = '/app/test/url';
my $data1  = GET_BODY $uri1;
my $data2  = GET_BODY $uri2;
my $data3  = GET_BODY $uri3;
my $data4  = GET_BODY $uri4;
my $data5  = GET_BODY $uri5;
my $data6  = GET_BODY $uri6;
my $data7  = GET_BODY $uri7;
my $data8  = GET_BODY $uri8;
my $data9  = GET_BODY $uri9;
my $data10 = GET_BODY $uri10;

ok t_cmp(
    $data1,
    'success',
    'testing browser() method',
  );

ok t_cmp(
    $data2,
    'success',
    'testing currency() method',
  );

ok t_cmp(
    $data3,
    'success',
    'testing date() method',
  );

ok t_cmp(
    $data4,
    'success',
    'testing date_is_future() method',
  );

ok t_cmp(
    $data5,
    'success',
    'testing date_is_past() method',
  );

ok t_cmp(
    $data6,
    'success',
    'testing domain() method',
  );

ok t_cmp(
    $data7,
    'success',
    'testing email() method',
  );

ok t_cmp(
    $data8,
    'success',
    'testing integer() method',
  );

ok t_cmp(
    $data9,
    'success',
    'testing html() method',
  );

ok t_cmp(
    $data10,
    'success',
    'testing url() method',
  );

done_testing();
