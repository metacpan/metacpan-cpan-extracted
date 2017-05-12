#!/usr/bin/perl

use AxKit2::Test tests => 9;

start_server("t/server1",
    [qw(uri_to_file test/config)],
    [
        'test1 test1 test1a test1b "test 1c"',
        'test2 test2',
        'test3 test3',
        'test4 true',
        'test5 5',
        'testthisthoroughly test6',
        'tESt-THis-thOROughly-As-wELL test7',
        'HTML_Response2_test test8',
    ]);

content_is('/test1','test1,test1a,test1b,test 1c',            'default config handler');
content_is('/test2','<undef>',                        'default store suppressed');
content_is('/test3','1',                              'value changed in validator');
content_is('/test4','1',                              'predefined validator');
content_is('/test5','6',                              'value changed in setter');

content_is('/test_this_thoroughly','test6',           'underscore');
content_is('/TestthisThoroughly','<undef>',           'case sensitivity on retrieve');
content_is('/TestThisThoroughlyAsWell','test7',       'camelcase sub and case insensitive config file');
content_is('/HTMLResponse2Test','test8',              'advanced camelcase sub');
