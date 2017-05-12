# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY );
use Test::More;

ok 1;

my $uri  = '/app/test';
my $data = GET_BODY $uri;

ok t_cmp(
    $data,
    'success',
    'testing default() method',
  );

done_testing();
