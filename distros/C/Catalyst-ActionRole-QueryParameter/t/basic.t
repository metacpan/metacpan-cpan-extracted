use strict;
use warnings FATAL =>'all';

use FindBin;
use Test::More;
use HTTP::Request::Common qw/GET/;

use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

is request(GET '/foo?page=100')->content, 'page';
is request(GET '/foo?row=100')->content, 'row';
is request(GET '/foo?page=100&row=100')->content, 'page_and_row';
is request(GET '/foo')->content, 'no_query';

is request(GET '/chained?page=100')->content, 'page';
is request(GET '/chained?row=100')->content, 'row';
is request(GET '/chained?page=100&row=100')->content, 'page_and_row';
is request(GET '/chained')->content, 'no_query';

is request(GET '/conditions?page=1')->content, 'is_one';
is request(GET '/conditions?page=100')->content, 'more_than_one';
is request(GET '/conditions?page=200')->content, 'equal_or_greater_200';
is request(GET '/conditions?page=200')->content, 'equal_or_greater_200';
is request(GET '/conditions')->content, 'no_query';
is request(GET '/conditions?page=AAAA')->content, 'no_query';

is request(GET '/configuration?page=1')->content, 'is_one';
is request(GET '/configuration?page=100')->content, 'more_than_one';
is request(GET '/configuration?page=200')->content, 'equal_or_greater_200';
is request(GET '/configuration?page=200')->content, 'equal_or_greater_200';
is request(GET '/configuration')->content, 'no_query';
is request(GET '/configuration?page=AAAA')->content, 'no_query';

SKIP: {
  skip "Don't test match_catures on older Catalyst versions", 2
    unless eval "use Catalyst 5.90007; 1";
  is request(GET '/matchcaptures/page?page=1')->content, 'has_page';
  is request(GET '/matchcaptures/page')->content, 'no_page';
}

is request(GET '/bar?bar=AAAA')->content, 'optional_bar';
is request(GET '/bar')->content, 'optional_bar';
is request(GET '/has_default?default=aaa')->content, 'has_default: aaa';
is request(GET '/has_default')->content, 'has_default: foobar';
is request(GET '/num?num=1000')->content, 'optional_num';
is request(GET '/num')->content, 'optional_num';

done_testing;
