#!/usr/bin/env perl
use strict;
use warnings;

no warnings 'redefine';

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;


is get('/sigmatch/test/23'), 'signaturematching/int', 'integer argument dispatched correctly';
is get('/sigmatch/test/foo'), 'signaturematching/str', 'string argument dispatched correctly';
is get('/sigmatch/test/f00'), 'signaturematching/rest', 'no match leads to other dispatched action';

is get('/sigmatch/opt_param?page=3'), 'page 3', 'query parameter';
is get('/sigmatch/opt_param?page=9&other=foo'), 'page 9', 'additional query parameter';

is get('/sigmatch/req_param?page=7'), 'page 7', 'required query parameter';
is get('/sigmatch/req_param'),        'no page', 'required query parameter fallback';

# TODO
#is get('/sigmatch/mid?page=3'), 'signaturematching/end_with_param', 'mid point with query parameter';
#is get('/sigmatch/mid'), 'signaturematching/end_no_param', 'mid point without query parameter';

is get('/sigmatch/with_list?filter=3'), '3', 'list-forced query parameter';
is get('/sigmatch/with_list'), '', 'list-forced empty query parameter list';
is get('/sigmatch/with_list?filter=3&filter=5'), '3, 5', 'list-forced query parameter with multiple';
is get('/sigmatch/with_list?filter=foo'), 'signaturematching/rest', 'invalid data in list-forced query';

is request(POST '/sigmatch/getpost', [id => 7])->content, 7, 'post request';

done_testing;
