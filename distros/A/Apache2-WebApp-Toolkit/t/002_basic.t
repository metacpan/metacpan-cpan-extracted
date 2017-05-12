# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
use Test::More;

ok 1;

my $uri1  = '/app/test';
my $uri2  = '/app/test/public';
my $uri3  = '/app/test/stash';
my $data1 = GET_BODY $uri1;
my $data2 = GET_BODY $uri2;
my $data3 = GET_BODY $uri3;

ok t_cmp(
    $data1,
    'success',
    'testing _default() method'
  );

ok t_cmp(
    $data2,
    'success',
    'testing public method'
  );

ok t_cmp(
    $data3,
    'success',
    'testing stash() method'
  );

done_testing();
