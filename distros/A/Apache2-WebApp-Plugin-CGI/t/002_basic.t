# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY POST );
use Test::More;

ok 1;

my $uri1  = '/app/test/params';
my $uri2  = '/app/test/redirect';
my $data1 = POST    ($uri1, [ hello => 'world', goodbye => 'world' ])->content;
my $data2 = GET_BODY $uri2;

ok t_cmp(
    $data1,
    'success',
    'testing params() method',
  );

ok t_cmp(
    $data2,
    'success',
    'testing redirect() method',
  );

done_testing();
