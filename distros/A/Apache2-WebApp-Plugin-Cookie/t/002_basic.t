# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY );
use Test::More;

ok 1;

Apache::TestRequest::user_agent( cookie_jar => {} );

my $uri1  = '/app/test/set';
my $uri2  = '/app/test/get';
my $uri3  = '/app/test/delete';
my $data1 = GET_BODY $uri1;
my $data2 = GET_BODY $uri2;
my $data3 = GET_BODY $uri3;

ok t_cmp(
    $data1,
    'success',
    'testing set() method',
  );

ok t_cmp(
    $data2,
    'success',
    'testing get() method',
  );

ok t_cmp(
    $data3,
    'success',
    'testing delete() method',
  );

done_testing();
