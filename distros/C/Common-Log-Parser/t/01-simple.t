
use Test2::V0;
use Test2::Tools::Compare;

use Common::Log::Parser v0.1.0 qw( split_log_line );

is split_log_line(qq{foo}), ["foo"];

# These examples come from https://web.archive.org/web/20210224022111/http://publib.boulder.ibm.com/tividd/td/ITWSA/ITWSA_info45/en_US/HTML/guide/c-logs.html#combined

is split_log_line(qq{125.125.125.125 - dsmith [10/Oct/1999:21:15:05 +0500] "GET /index.html HTTP/1.0" 200 1043}), [
    '125.125.125.125',                 #
    '-',                               #
    'dsmith',                          #
    '[10/Oct/1999:21:15:05 +0500]',    #
    '"GET /index.html HTTP/1.0"',      #
    200,                               #
    1043                               #
];

is split_log_line(qq{125.125.125.125 - dsmith [10/Oct/1999:21:15:05 +0500] "GET /index.html HTTP/1.0" 200 1043\n}), [
    '125.125.125.125',                 #
    '-',                               #
    'dsmith',                          #
    '[10/Oct/1999:21:15:05 +0500]',    #
    '"GET /index.html HTTP/1.0"',      #
    200,                               #
    1043                               #
];

is split_log_line(
qq{125.125.125.125 - dsmith [10/Oct/1999:21:15:05 +0500] "GET /index.html HTTP/1.0" 200 1043 "http://www.ibm.com/" "Mozilla/4.05 [en] (WinNT; I)" "USERID=CustomerA;IMPID=01234"}
), [
    '125.125.125.125',                   #
    '-',                                 #
    'dsmith',                            #
    '[10/Oct/1999:21:15:05 +0500]',      #
    '"GET /index.html HTTP/1.0"',        #
    200,                                 #
    1043,                                #
    '"http://www.ibm.com/"',             #
    '"Mozilla/4.05 [en] (WinNT; I)"',    #
    '"USERID=CustomerA;IMPID=01234"'     #
];

is split_log_line(q{125.125.125.125 - dsmith [10/Oct/1999:21:15:05 +0500] "GET /\"foo\" HTTP/1.0" 200 1043}), [
    '125.125.125.125',                 #
    '-',                               #
    'dsmith',                          #
    '[10/Oct/1999:21:15:05 +0500]',    #
    '"GET /\"foo\" HTTP/1.0"',         #
    200,                               #
    1043                               #
], "handle escaped quotes";

done_testing;
