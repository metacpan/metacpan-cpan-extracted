#!perl

use Test::Most;

use HTTP::Date;
use HTTP::Status qw/ :constants /;
use HTTP::Request::Common;
use Time::Seconds qw/ ONE_DAY /;

use lib 't/lib';
use Catalyst::Test 'App';

my $date = time2str( ONE_DAY );

subtest "Ok" => sub {
    my $res = request(GET '/');
    is $res->code, HTTP_OK, 'Expected HTTP response';
    is $res->header('Last-Modified'), $date, 'Last-Modified header';
};

subtest "Ok (If-Modified-Since past)" => sub {
    my $res = request(GET '/', 'if-modified-since' => time2str( ONE_DAY - 1 ) );
    is $res->code, HTTP_OK, 'Expected HTTP response';
    is $res->header('Last-Modified'), $date, 'Last-Modified header';
};

subtest "Not Modified" => sub {
    my $res = request(GET '/', 'if-modified-since' => $date );
    is $res->code, HTTP_NOT_MODIFIED, 'Expected HTTP response';
    is $res->header('Last-Modified'), $date, 'Last-Modified header';
};

subtest "Not Modified (future)" => sub {
    my $res = request(GET '/', 'if-modified-since' => time2str( ONE_DAY + 1) );
    is $res->code, HTTP_NOT_MODIFIED, 'Expected HTTP response';
    is $res->header('Last-Modified'), $date, 'Last-Modified header';
};




done_testing;
