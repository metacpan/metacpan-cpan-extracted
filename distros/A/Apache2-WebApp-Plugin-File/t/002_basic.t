# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_HEAD );
use Test::More;

ok 1;

my $uri1   = '/app/test/open';
my $uri2   = '/app/test/download';

my $data1  = GET_HEAD $uri1;
my $data2  = GET_HEAD $uri2;

ok t_cmp(
    $data1,
    qr/Content-Type: image\/gif/,
    'testing open() method',
  );

ok t_cmp(
    $data2,
    qr/Content-Disposition: attachment;filename=test\.gif/,
    'testing download() method',
  );

done_testing();
