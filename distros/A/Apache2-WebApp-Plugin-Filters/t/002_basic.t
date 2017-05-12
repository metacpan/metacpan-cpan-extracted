# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_basic.t -

use Apache::Test qw( :withtestmore );
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY );
use Test::More;

ok 1;

my $uri1  = '/app/test/encode_url';
my $uri2  = '/app/test/decode_url';
my $uri3  = '/app/test/strip_domain_alias';
my $uri4  = '/app/test/strip_html';
my $uri5  = '/app/test/untaint_html';
my $data1 = GET_BODY $uri1;
my $data2 = GET_BODY $uri2;
my $data3 = GET_BODY $uri3;
my $data4 = GET_BODY $uri4;
my $data5 = GET_BODY $uri5;

ok t_cmp(
    $data1,
    'success',
    'testing encode_url() method',
  );

ok t_cmp(
    $data2,
    'success',
    'testing decode_url() method',
  );

ok t_cmp(
    $data3,
    'success',
    'testing strip_domain_alias() method',
  );

ok t_cmp(
    $data4,
    'success',
    'testing strip_html() method',
  );

ok t_cmp(
    $data5,
    'success',
    'testing untaint_html() method',
  );

done_testing();
