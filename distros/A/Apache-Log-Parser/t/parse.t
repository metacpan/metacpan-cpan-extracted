use strict;
use Test::More;
use Test::Deep;
use Test::Exception;

use_ok "Apache::Log::Parser";

{
    is (Apache::Log::Parser::dequote(''), "");
    is (Apache::Log::Parser::dequote('hoge'), "hoge");
    is (Apache::Log::Parser::dequote('"hoge"'), "hoge");
    is (Apache::Log::Parser::dequote('hoge\\"pos'), 'hoge\\"pos');
    is (Apache::Log::Parser::dequote('"hoge\\"pos"'), 'hoge"pos');
}

{
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote(''));
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote('hoge'));
    ok (  Apache::Log::Parser::has_unquoted_tail_doublequote('hoge"'));
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\"'));
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\"x'));
    ok (  Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\\\"'));
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\\\\\"'));
    ok (  Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\\\\\\\"'));
    ok (! Apache::Log::Parser::has_unquoted_tail_doublequote('hoge\\\\\\\\\\"'));
}

# debug
my $log_z1 = '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891 "-" "DoCoMo/2.0 P03B(c500;TB;W24H16)" 3210';
my $set_z1 = ['192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891',
              '-', 'DoCoMo/2.0 P03B(c500;TB;W24H16)', '3210'];
my $map_z1 = {rhost => '192.168.0.1', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /x/i.cgi/net/0000/ HTTP/1.1', method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
              status => '200', bytes => '9891',
              referer => '-', agent => 'DoCoMo/2.0 P03B(c500;TB;W24H16)', duration => '3210'};


# combined
my $log_a1 = '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891 "-" "DoCoMo/2.0 P03B(c500;TB;W24H16)"';
my $set_a1 = ['192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891',
              '-', 'DoCoMo/2.0 P03B(c500;TB;W24H16)'];
my $map_a1 = {rhost => '192.168.0.1', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /x/i.cgi/net/0000/ HTTP/1.1', method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
              status => '200', bytes => '9891',
              referer => '-', agent => 'DoCoMo/2.0 P03B(c500;TB;W24H16)'};
my $log_a2 = '192.0.2.130 - - [07/Feb/2011:10:59:59 +0900] "GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1" 200 35 "-" "DoCoMo/2.0 F905i(c100;TB;W24H17)"';
my $set_a2 = ['192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35',
              '-', 'DoCoMo/2.0 F905i(c100;TB;W24H17)'];
my $map_a2 = {rhost => '192.0.2.130', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1',
              method => 'GET', path => '/hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON', proto => 'HTTP/1.1',
              status => '200', bytes => '35',
              referer => '-', agent => 'DoCoMo/2.0 F905i(c100;TB;W24H17)'};
my $log_a3 = '203.0.113.254 - - [07/Feb/2011:10:59:59 -0700] "GET /x/i.cgi/movie/0001/-0002 HTTP/1.1" 200 14462 "http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1" "DoCoMo/2.0 F08A3(c500;TB;W30H20)"';
my $set_a3 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462',
              'http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1', 'DoCoMo/2.0 F08A3(c500;TB;W30H20)'];
my $map_a3 = {rhost => '203.0.113.254', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 -0700', date => '07/Feb/2011', time => '10:59:59', timezone => '-0700',
              request => 'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/movie/0001/-0002', proto => 'HTTP/1.1',
              status => '200', bytes => '14462',
              referer => 'http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1',
              agent => 'DoCoMo/2.0 F08A3(c500;TB;W30H20)'};

# TAB separated combined
my $log_b1 = "203.0.113.254\t-\t-\t[07/Feb/2011:10:59:59 -0700]\t\"GET /x/i.cgi/movie/0001/-0002 HTTP/1.1\"\t200\t14462\t\"-\"\t\"DoCoMo/2.0 F08A3(c500;TB;W30H20)\"";
my $set_b1 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462',
              '-', 'DoCoMo/2.0 F08A3(c500;TB;W30H20)'];
my $log_b2 = "203.0.113.254\t-\t-\t[07/Feb/2011:10:59:59 -0700]\t\"GET /x/i.cgi/movie/0001/-0002 HTTP/1.1\"\t200\t14462\t\"http://headlines.yahoo.co.jp/hl\"\t\"DoCoMo/2.0 F08A3(c500;TB;W30H20)\"";
my $set_b2 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462',
              'http://headlines.yahoo.co.jp/hl', 'DoCoMo/2.0 F08A3(c500;TB;W30H20)'];

# common
my $log_c1 = '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891';
my $set_c1 = ['192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891'];
my $map_c1 = {rhost => '192.168.0.1', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /x/i.cgi/net/0000/ HTTP/1.1', method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
              status => '200', bytes => '9891'};
my $log_c2 = '192.0.2.130 - - [07/Feb/2011:10:59:59 +0900] "GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1" 200 35';
my $set_c2 = ['192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35'];
my $map_c2 = {rhost => '192.0.2.130', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1',
              method => 'GET', path => '/hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON', proto => 'HTTP/1.1',
              status => '200', bytes => '35'};
my $log_c3 = '203.0.113.254 - - [07/Feb/2011:10:59:59 -0700] "GET /x/i.cgi/movie/0001/-0002 HTTP/1.1" 200 14462';
my $set_c3 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462'];
my $map_c3 = {rhost => '203.0.113.254', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 -0700', date => '07/Feb/2011', time => '10:59:59', timezone => '-0700',
              request => 'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/movie/0001/-0002', proto => 'HTTP/1.1',
              status => '200', bytes => '14462'};

# TAB separated common
my $log_d1 = "192.168.0.1\t-\t-\t[07/Feb/2011:10:59:59 +0900]\t\"GET /x/i.cgi/net/0000/ HTTP/1.1\"\t200\t9891";
my $set_d1 = ['192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891'];
my $log_d2 = "192.0.2.130\t-\t-\t[07/Feb/2011:10:59:59 +0900]\t\"GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1\"\t200\t35";
my $set_d2 = ['192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35'];
my $log_d3 = "203.0.113.254\t-\t-\t[07/Feb/2011:10:59:59 -0700]\t\"GET /x/i.cgi/movie/0001/-0002 HTTP/1.1\"\t200\t14462";
my $set_d3 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462'];

# common with vhost
my $log_e1 = 'example.com 192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891';
my $set_e1 = ['example.com', '192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891'];
my $map_e1 = {vhost => 'example.com', rhost => '192.168.0.1', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /x/i.cgi/net/0000/ HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
              status => '200', bytes => '9891'};
my $log_e2 = 'localhost 192.0.2.130 - - [07/Feb/2011:10:59:59 +0900] "GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1" 200 35';
my $set_e2 = ['localhost', '192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35'];
my $log_e3 = 'host-x.example.jp 203.0.113.254 - - [07/Feb/2011:10:59:59 -0700] "GET /x/i.cgi/movie/0001/-0002 HTTP/1.1" 200 14462';
my $set_e3 = ['host-x.example.jp', '203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462'];

# TAB separated common with vhost
my $log_f1 = "example.com\t192.168.0.1\t-\t-\t[07/Feb/2011:10:59:59 +0900]\t\"GET /x/i.cgi/net/0000/ HTTP/1.1\"\t200\t9891";
my $set_f1 = ['example.com', '192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891'];
my $log_f2 = "localhost\t192.0.2.130\t-\t-\t[07/Feb/2011:10:59:59 +0900]\t\"GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1\"\t200\t35";
my $set_f2 = ['localhost', '192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35'];
my $log_f3 = "host-x.example.jp\t203.0.113.254\t-\t-\t[07/Feb/2011:10:59:59 -0700]\t\"GET /x/i.cgi/movie/0001/-0002 HTTP/1.1\"\t200\t14462";
my $set_f3 = ['host-x.example.jp', '203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462'];


# customized format: combined + %v + mod_usertrack cookie + cellular phone ID + %D
my @customized_fields = qw( rhost logname user datetime request status bytes referer agent vhost usertrack mobileid request_duration );

# log pattern for non-double-quote-quoted vhost
my $log_x1 = '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891 "-" "DoCoMo/2.0 P03B(c500;TB;W24H16)" virtualhost.example.jp "192.0.2.16794832933550" "09011112222333_xx.ezweb.ne.jp" 533593';
my $set_x1 = ['192.168.0.1', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /x/i.cgi/net/0000/ HTTP/1.1', '200', '9891',
              '-', 'DoCoMo/2.0 P03B(c500;TB;W24H16)',
              'virtualhost.example.jp', '192.0.2.16794832933550', '09011112222333_xx.ezweb.ne.jp',
              '533593'];
my $map_x1 = {rhost => '192.168.0.1', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900',
              date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /x/i.cgi/net/0000/ HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
              status => '200', bytes => '9891',
              referer => '-', agent => 'DoCoMo/2.0 P03B(c500;TB;W24H16)',
              vhost => 'virtualhost.example.jp',
              usertrack => '192.0.2.16794832933550', mobileid => '09011112222333_xx.ezweb.ne.jp',
              request_duration => '533593'};
my $log_x2 = '192.0.2.130 - - [07/Feb/2011:10:59:59 +0900] "GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1" 200 35 "-" "DoCoMo/2.0 F905i(c100;TB;W24H17)" "virtualhost.example.jp" "192.0.2.16794832933550" "-" 533593';
my $set_x2 = ['192.0.2.130', '-', '-', '07/Feb/2011:10:59:59 +0900',
              'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1', '200', '35',
              '-', 'DoCoMo/2.0 F905i(c100;TB;W24H17)',
              'virtualhost.example.jp', '192.0.2.16794832933550', '-',
              '533593'];
my $map_x2 = {rhost => '192.0.2.130', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 +0900',
              date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
              request => 'GET /hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON HTTP/1.1',
              method => 'GET', path => '/hoge.cgi?param1=9999-1&param2=AAABC&param3=-&ref=/x/i.cgi/net/000&guid=ON', proto => 'HTTP/1.1',
              status => '200', bytes => '35',
              referer => '-', agent => 'DoCoMo/2.0 F905i(c100;TB;W24H17)',
              vhost => 'virtualhost.example.jp', usertrack => '192.0.2.16794832933550', mobileid => '-',
              request_duration => '533593'};
my $log_x3 = '203.0.113.254 - - [07/Feb/2011:10:59:59 -0700] "GET /x/i.cgi/movie/0001/-0002 HTTP/1.1" 200 14462 "http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1" "DoCoMo/2.0 F08A3(c500;TB;W30H20)" "virtualhost.example.jp" "-" "-" 533593';
my $set_x3 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462',
              'http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1', 'DoCoMo/2.0 F08A3(c500;TB;W30H20)',
              'virtualhost.example.jp', '-', '-',
              '533593'];
my $map_x3 = {rhost => '203.0.113.254', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 -0700',
              date => '07/Feb/2011', time => '10:59:59', timezone => '-0700',
              request => 'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/movie/0001/-0002', proto => 'HTTP/1.1',
              status => '200', bytes => '14462',
              referer => 'http://www.google.co.jp/search?hl=ja&&sa=X&ei=HqhQTf2ONoKlcf6ZtNcG&ved=0CCsQBSgA&q=movie&spell=1',
              agent => 'DoCoMo/2.0 F08A3(c500;TB;W30H20)',
              vhost => 'virtualhost.example.jp', usertrack => '-', mobileid => '-',
              request_duration => '533593'};

# TAB separated customized format: combined + %v + mod_usertrack cookie + cellular phone ID + %D
my $log_y1 = "203.0.113.254\t-\t-\t[07/Feb/2011:10:59:59 -0700]\t\"GET /x/i.cgi/movie/0001/-0002 HTTP/1.1\"\t200\t14462\t\"http://headlines.yahoo.co.jp/hl\"\t\"DoCoMo/2.0 F08A3(c500;TB;W30H20)\"\t\"virtualhost.example.jp\"\t\"192.0.2.16794832933550\"\t\"09011112222333_xx.ezweb.ne.jp\"\t533593";
my $set_y1 = ['203.0.113.254', '-', '-', '07/Feb/2011:10:59:59 -0700',
              'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1', '200', '14462',
              'http://headlines.yahoo.co.jp/hl', 'DoCoMo/2.0 F08A3(c500;TB;W30H20)',
              'virtualhost.example.jp', '192.0.2.16794832933550', '09011112222333_xx.ezweb.ne.jp',
              '533593'];
my $map_y1 = {rhost => '203.0.113.254', logname => '-', user => '-',
              datetime => '07/Feb/2011:10:59:59 -0700',
              date => '07/Feb/2011', time => '10:59:59', timezone => '-0700',
              request => 'GET /x/i.cgi/movie/0001/-0002 HTTP/1.1',
              method => 'GET', path => '/x/i.cgi/movie/0001/-0002', proto => 'HTTP/1.1',
              status => '200', bytes => '14462',
              referer => 'http://headlines.yahoo.co.jp/hl', agent => 'DoCoMo/2.0 F08A3(c500;TB;W30H20)',
              vhost => 'virtualhost.example.jp', usertrack => '192.0.2.16794832933550', mobileid => '09011112222333_xx.ezweb.ne.jp',
              request_duration => '533593'};

{
    my @result;

    # debug
    @result = Apache::Log::Parser::separate_log_items(' ', $log_z1);
    cmp_set (\@result, $set_z1);

    # combined
    @result = Apache::Log::Parser::separate_log_items(' ', $log_a1);
    cmp_set (\@result, $set_a1);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_a2);
    cmp_set (\@result, $set_a2);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_a3);
    cmp_set (\@result, $set_a3);

    # TAB separated combined
    @result = Apache::Log::Parser::separate_log_items("\t", $log_b1);
    cmp_set (\@result, $set_b1);
    @result = Apache::Log::Parser::separate_log_items("\t", $log_b2);
    cmp_set (\@result, $set_b2);

    # common
    @result = Apache::Log::Parser::separate_log_items(' ', $log_c1);
    cmp_set (\@result, $set_c1);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_c2);
    cmp_set (\@result, $set_c2);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_c3);
    cmp_set (\@result, $set_c3);

    # TAB separated common
    @result = Apache::Log::Parser::separate_log_items("\t", $log_d1);
    cmp_set (\@result, $set_d1);
    @result = Apache::Log::Parser::separate_log_items("\t", $log_d2);
    cmp_set (\@result, $set_d2);
    @result = Apache::Log::Parser::separate_log_items("\t", $log_d3);
    cmp_set (\@result, $set_d3);

    # common with vhost
    @result = Apache::Log::Parser::separate_log_items(' ', $log_e1);
    cmp_set (\@result, $set_e1);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_e2);
    cmp_set (\@result, $set_e2);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_e3);
    cmp_set (\@result, $set_e3);

    # TAB separated common with vhost
    @result = Apache::Log::Parser::separate_log_items("\t", $log_f1);
    cmp_set (\@result, $set_f1);
    @result = Apache::Log::Parser::separate_log_items("\t", $log_f2);
    cmp_set (\@result, $set_f2);
    @result = Apache::Log::Parser::separate_log_items("\t", $log_f3);
    cmp_set (\@result, $set_f3);

    # customized format
    @result = Apache::Log::Parser::separate_log_items(' ', $log_x1);
    cmp_set (\@result, $set_x1);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_x2);
    cmp_set (\@result, $set_x2);
    @result = Apache::Log::Parser::separate_log_items(' ', $log_x3);
    cmp_set (\@result, $set_x3);

    # TAB separated customized format
    @result = Apache::Log::Parser::separate_log_items("\t", $log_y1);
    cmp_set (\@result, $set_y1);
}

{
    my $std_parser = new_ok('Apache::Log::Parser' => ['strict' => 1]);
    cmp_deeply ($std_parser->parse($log_z1), $map_z1);

    cmp_deeply ($std_parser->parse($log_a1), $map_a1);
    cmp_deeply ($std_parser->parse($log_a2), $map_a2);
    cmp_deeply ($std_parser->parse($log_a3), $map_a3);

    cmp_deeply ($std_parser->parse($log_c1), $map_c1);
    cmp_deeply ($std_parser->parse($log_c2), $map_c2);
    cmp_deeply ($std_parser->parse($log_c3), $map_c3);

    cmp_deeply ($std_parser->parse($log_e1), $map_e1);

    my @instanciate_options = ( strict => [
        ["\t", \@customized_fields, sub{my $x=shift;defined($x->{vhost}) and defined($x->{usertrack}) and defined($x->{mobileid})}],
        [" ", \@customized_fields, sub{my $x=shift;defined($x->{vhost}) and defined($x->{usertrack}) and defined($x->{mobileid})}],
        'debug',
        'combined',
        'common',
        'vhost_common',
    ]);
    my $parser = new_ok('Apache::Log::Parser' => \@instanciate_options);

    cmp_deeply ($parser->parse($log_z1), $map_z1);

    cmp_deeply ($parser->parse($log_a1), $map_a1);
    cmp_deeply ($parser->parse($log_a2), $map_a2);
    cmp_deeply ($parser->parse($log_a3), $map_a3);

    cmp_deeply ($parser->parse($log_c1), $map_c1);
    cmp_deeply ($parser->parse($log_c2), $map_c2);
    cmp_deeply ($parser->parse($log_c3), $map_c3);

    cmp_deeply ($parser->parse($log_e1), $map_e1);

    cmp_deeply ($parser->parse($log_x1), $map_x1);
    cmp_deeply ($parser->parse($log_x2), $map_x2);
    cmp_deeply ($parser->parse($log_x3), $map_x3);
    cmp_deeply ($parser->parse($log_y1), $map_y1);
}

{
    my $fast_basic = Apache::Log::Parser->new(fast => 1);

    cmp_deeply ($fast_basic->parse($log_a1), $map_a1);
    cmp_deeply ($fast_basic->parse($log_a2), $map_a2);
    cmp_deeply ($fast_basic->parse($log_a3), $map_a3);

    cmp_deeply ($fast_basic->parse($log_c1), $map_c1);
    cmp_deeply ($fast_basic->parse($log_c2), $map_c2);
    cmp_deeply ($fast_basic->parse($log_c3), $map_c3);

    # vhost style unacceptable
    ok (! $fast_basic->parse($log_e1));

    # combined with %D : unexpected fields are ignored.
    cmp_deeply (
        $fast_basic->parse(
            q{192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891 "-" "DoCoMo/2.0 P03B(c500;TB;W24H16)" 520} ),
        {
            rhost => '192.168.0.1', logname => '-', user => '-',
            datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
            request => 'GET /x/i.cgi/net/0000/ HTTP/1.1', method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
            status => '200', bytes => '9891',
            referer => '-', agent => 'DoCoMo/2.0 P03B(c500;TB;W24H16)',
        }
    );

    my $fast_custom = Apache::Log::Parser->new(fast => [[qw(referer agent vhost usertrack mobileid request_duration)], 'debug', 'combined', 'common']);

    cmp_deeply ($fast_custom->parse($log_z1), $map_z1);

    cmp_deeply ($fast_custom->parse($log_a1), $map_a1);
    cmp_deeply ($fast_custom->parse($log_a2), $map_a2);
    cmp_deeply ($fast_custom->parse($log_a3), $map_a3);

    cmp_deeply ($fast_custom->parse($log_c1), $map_c1);
    cmp_deeply ($fast_custom->parse($log_c2), $map_c2);
    cmp_deeply ($fast_custom->parse($log_c3), $map_c3);

    # vhost style unacceptable
    ok (! $fast_custom->parse($log_e1));

    # combined with %D : unexpected fields are ignored.
    cmp_deeply (
        $fast_custom->parse(
            q{192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] "GET /x/i.cgi/net/0000/ HTTP/1.1" 200 9891 "-" "DoCoMo/2.0 P03B(c500;TB;W24H16)" 520} ),
        {
            rhost => '192.168.0.1', logname => '-', user => '-',
            datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
            request => 'GET /x/i.cgi/net/0000/ HTTP/1.1', method => 'GET', path => '/x/i.cgi/net/0000/', proto => 'HTTP/1.1',
            status => '200', bytes => '9891',
            referer => '-', agent => 'DoCoMo/2.0 P03B(c500;TB;W24H16)',
            duration => '520',
        }
    );

    # custom style logs
    cmp_deeply ($fast_custom->parse($log_x1), $map_x1);
    cmp_deeply ($fast_custom->parse($log_x2), $map_x2);
    cmp_deeply ($fast_custom->parse($log_x3), $map_x3);
    cmp_deeply ($fast_custom->parse($log_y1), $map_y1);
}

{
    my $fast = Apache::Log::Parser->new(fast => 1);
    my $strict = Apache::Log::Parser->new(strict => 1);

    my $build_log = sub {
        my ($request) = @_;
        '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] ' . $request . ' 200 9891';
    };

    my $r1 = $build_log->('"GET /index HTTP/1.1"'); # normal common

    my $r3 = $build_log->('"GET index HTTP/1.1"'); # path without '/'
    my $r4 = $build_log->('"GET /x index HTTP/1.1"'); # path with space
    my $r5 = $build_log->('"GET /hoge/pos\".html HTTP/1.1"'); # path with quoted-"

    my $valid_parsed_map = {
        rhost => '192.168.0.1', logname => '-', user => '-',
        datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
        status => '200', bytes => '9891'
    };

    cmp_deeply ($fast->parse($r1), {
        %{$valid_parsed_map},
        request => 'GET /index HTTP/1.1', method => 'GET', path => '/index', proto => 'HTTP/1.1'
    });
    cmp_deeply ($strict->parse($r1), {
        %{$valid_parsed_map},
        request => 'GET /index HTTP/1.1', method => 'GET', path => '/index', proto => 'HTTP/1.1'
    });

    cmp_deeply ($fast->parse($r3), {
        %{$valid_parsed_map},
        request => 'GET index HTTP/1.1', method => 'GET', path => 'index', proto => 'HTTP/1.1'
    });
    cmp_deeply ($strict->parse($r3), {
        %{$valid_parsed_map},
        request => 'GET index HTTP/1.1', method => 'GET', path => 'index', proto => 'HTTP/1.1'
    });

    ok (! $fast->parse($r4));
    cmp_deeply ($strict->parse($r4), {
        %{$valid_parsed_map},
        request => 'GET /x index HTTP/1.1', method => 'GET', path => '/x index', proto => 'HTTP/1.1'
    });

    cmp_deeply ($fast->parse($r5), {
        %{$valid_parsed_map},
        request => 'GET /hoge/pos\".html HTTP/1.1', method => 'GET', path => '/hoge/pos\".html', proto => 'HTTP/1.1'
    });
    cmp_deeply ($strict->parse($r5), {
        %{$valid_parsed_map},
        request => 'GET /hoge/pos".html HTTP/1.1', method => 'GET', path => '/hoge/pos".html', proto => 'HTTP/1.1'
    });

    my $build_log09 = sub {
        my ($request) = @_;
        '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] ' . $request . ' 200 -';
    };
    my $valid_parsed_map09 = {
        rhost => '192.168.0.1', logname => '-', user => '-',
        datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
        status => '200', bytes => '-'
    };

    my $r6 = $build_log09->('"GET /index.html"'); # HTTP/0.9 ? without HTTP protocol version
    cmp_deeply ($fast->parse($r6), {
        %{$valid_parsed_map09},
        request => 'GET /index.html', method => 'GET', path => '/index.html', proto => undef
    });
    ok (! $fast->parse($r6)->{proto});
    cmp_deeply ($strict->parse($r6), {
        %{$valid_parsed_map09},
        request => 'GET /index.html', method => 'GET', path => '/index.html', proto => undef
    });
    ok (! $strict->parse($r6)->{proto});

    my $r7 = $build_log09->('"lzh\x81GET /music/19810/index.html HTTP/1.1"'); # broken data before HTTP method
    cmp_deeply ($fast->parse($r7), {
        %{$valid_parsed_map09},
        request => 'lzh\x81GET /music/19810/index.html HTTP/1.1', method => 'lzh\x81GET', path => '/music/19810/index.html', proto => 'HTTP/1.1'
    });
    cmp_deeply ($strict->parse($r7), {
        %{$valid_parsed_map09},
        request => 'lzh\x81GET /music/19810/index.html HTTP/1.1', method => 'lzh\x81GET', path => '/music/19810/index.html', proto => 'HTTP/1.1'
    });

    my $r8 = $build_log09->('""'); # time out before HTTP request message
    ok (! $fast->parse($r8));
    ok (! $strict->parse($r8));

}

{
    my $fast = Apache::Log::Parser->new(fast => 1);
    my $strict = Apache::Log::Parser->new(strict => 1);

    my $fast_custom = Apache::Log::Parser->new(fast => [[qw(referer agent request_duration)], 'combined', 'common']);
    my $strict_custom = Apache::Log::Parser->new(strict => [
        [" ", [qw(rhost logname user datetime request status bytes referer agent request_duration)], sub{my $x=shift;defined($x->{request_duration}) and $x->{request_duration} =~ /^\d+$/;}],
        'combined',
        'common',
    ]);

    my $build_log = sub {
        my ($request, $referer, $agent, $appendix) = @_;
        if ($appendix) {
            return '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] ' . $request . ' 200 9891 ' . $referer . ' ' . $agent . ' ' . $appendix;
        }
        '192.168.0.1 - - [07/Feb/2011:10:59:59 +0900] ' . $request . ' 200 9891 ' . $referer . ' ' . $agent;
    };
    my $req = '"GET /index.html HTTP/1.1"';
    my $ref = '"http://example.com/hoge"';
    my $agent = '"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.94 Safari/534.13"';

    my $valid_parsed_map = {
        rhost => '192.168.0.1', logname => '-', user => '-',
        datetime => '07/Feb/2011:10:59:59 +0900', date => '07/Feb/2011', time => '10:59:59', timezone => '+0900',
        request => 'GET /index.html HTTP/1.1', method => 'GET', path => '/index.html', proto => 'HTTP/1.1',
        status => '200', bytes => '9891',
        referer => 'http://example.com/hoge',
        agent => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.94 Safari/534.13',
    };

    my $r1 = $build_log->($req, $ref, $agent); # normal combined
    cmp_deeply ($fast->parse($r1), $valid_parsed_map);
    cmp_deeply ($strict->parse($r1), $valid_parsed_map);

    my $r2 = $build_log->($req, $ref, $agent, '850'); # normal combined + %D
    cmp_deeply ($fast->parse($r2), $valid_parsed_map);
    cmp_deeply ($strict->parse($r2), {
        %{$valid_parsed_map},
        duration => '850'
    });

    my $r3 = $build_log->('"GET /x index.html HTTP/1.1"', $ref, $agent); # request with space
    ok (! $fast->parse($r3));
    cmp_deeply ($strict->parse($r3), {
        %{$valid_parsed_map},
        request => 'GET /x index.html HTTP/1.1', method => 'GET', path => '/x index.html', proto => 'HTTP/1.1'
    });

    my $r4 = $build_log->($req, '"http://example.com/hoge\"pos"', $agent); # referer with quoted-"
    # cmp_deeply ($fast->parse($r4), {
    #     %{$valid_parsed_map},
    #     referer => 'http://example.com/hoge\\',
    #     agent => 'pos' # oh...
    # });
    cmp_deeply ($strict->parse($r4), {
        %{$valid_parsed_map},
        referer => 'http://example.com/hoge"pos'
    });

    my $r5 = $build_log->($req, $ref, '"Mozilla/5.0 \"TESTING!\""'); # agent with quoted-"
    # cmp_deeply ($fast->parse($r5), {
    #     %{$valid_parsed_map},
    #     agent => 'Mozilla/5.0 \\' # oh...
    # });
    cmp_deeply ($strict->parse($r5), {
        %{$valid_parsed_map},
        agent => 'Mozilla/5.0 "TESTING!"'
    });

    my $r6 = $build_log->($req, '"http://example.com/hoge\"pos"', $agent, '850'); # referer with quoted-"
    # cmp_deeply ($fast->parse($r6), {
    #     %{$valid_parsed_map},
    #     referer => 'http://example.com/hoge\\',
    #     agent => 'pos' # oh...
    # });
    # cmp_deeply ($fast_custom->parse($r6), {
    #     %{$valid_parsed_map},
    #     referer => 'http://example.com/hoge\\',
    #     agent => 'pos', # oh...
    #     request_duration => substr($agent, 1, length($agent) - 2), # oh...
    # });
    cmp_deeply ($strict->parse($r6), {
        %{$valid_parsed_map},
        referer => 'http://example.com/hoge"pos',
        duration => '850'
    });
    cmp_deeply ($strict_custom->parse($r6), {
        %{$valid_parsed_map},
        referer => 'http://example.com/hoge"pos',
        agent => substr($agent, 1, length($agent) - 2),
        request_duration => '850',
    });

    my $r7 = $build_log->($req, $ref, '"Mozilla/5.0 \"TESTING!\""', '850'); # agent with quoted-"
    # cmp_deeply ($fast->parse($r7), {
    #     %{$valid_parsed_map},
    #     agent => 'Mozilla/5.0 \\' # oh...
    # });
    # cmp_deeply ($fast_custom->parse($r7), {
    #     %{$valid_parsed_map},
    #     agent => 'Mozilla/5.0 \\', # oh...
    #     request_duration => 'TESTING!\\', # oh...
    # });
    cmp_deeply ($strict_custom->parse($r7), {
        %{$valid_parsed_map},
        agent => 'Mozilla/5.0 "TESTING!"',
        request_duration => '850'
    });

    my $r8 = $build_log->($req, '"-"', '""'); # blank string for agent
    cmp_deeply ($fast->parse($r8), {
        %{$valid_parsed_map},
        referer => '-',
        agent => ''
    });
    cmp_deeply ($fast_custom->parse($r8), {
        %{$valid_parsed_map},
        referer => '-',
        agent => '',
    });
    ok (! exists( $fast_custom->parse($r8)->{request_duration} ));
    cmp_deeply ($strict->parse($r8), {
        %{$valid_parsed_map},
        referer => '-',
        agent => ''
    });
    cmp_deeply ($strict_custom->parse($r8), {
        %{$valid_parsed_map},
        referer => '-',
        agent => '',
    });
    ok (! exists( $strict_custom->parse($r8)->{request_duration} ));

    my $r9 = $build_log->($req, '""', '"-"'); # blank string for referer
    cmp_deeply ($fast->parse($r9), {
        %{$valid_parsed_map},
        referer => '',
        agent => '-'
    });
    cmp_deeply ($fast_custom->parse($r9), {
        %{$valid_parsed_map},
        referer => '',
        agent => '-',
    });
    ok (! exists( $fast_custom->parse($r9)->{request_duration} ));
    cmp_deeply ($strict->parse($r9), {
        %{$valid_parsed_map},
        referer => '',
        agent => '-'
    });
    cmp_deeply ($strict_custom->parse($r9), {
        %{$valid_parsed_map},
        referer => '',
        agent => '-',
    });
    ok (! exists( $strict_custom->parse($r9)->{request_duration} ));
}

done_testing;
