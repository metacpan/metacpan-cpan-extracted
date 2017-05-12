#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;
use XML::Fast;

BEGIN { 
    plan tests => 17;

    use_ok('API::Plesk::Response'); 
}

isa_ok(
    API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => {}
    ),
    'API::Plesk::Response'
);

my $res = API::Plesk::Response->new(
        operator  => 'customer',
        operation => 'get',
        response  => xml2hash('
<?xml version="1.0" encoding="utf-8"?>
<packet>
    <customer>
        <get>
            <result>
                <status>ok</status>
                <id>123</id>
                <guid>123456</guid>
                <data>
                    <test>qwerty</test>
                </data>
            </result>
        </get>
    </customer>
</packet>', array => ['get', 'result'])
);
ok($res->is_success);
is($res->id, 123);
is($res->guid, 123456);
is($res->results->[0]->{status}, 'ok');
is($res->data->[0]->{test}, 'qwerty');

$res = API::Plesk::Response->new(
        operator  => 'webspace',
        operation => 'add',
        response  => xml2hash(q|
<?xml version="1.0" encoding="UTF-8"?>
<packet version="1.6.3.1"><webspace><add><result><status>error</status><errcode>1018</errcode><errtext>Unable to create hosting on ip 12.34.56.78. Ip address does not exist in client's pool</errtext></result></add></webspace></packet>
|, array => ['add', 'result'])
);
ok(!$res->is_success);
ok(!$res->id);
ok(!$res->guid);
is($res->{results}->[0]->{status}, 'error');
is($res->error_code, '1018');
is($res->error_text, 'Unable to create hosting on ip 12.34.56.78. Ip address does not exist in client\'s pool');
is($res->error_codes->[0], '1018');
is($res->error_texts->[0], 'Unable to create hosting on ip 12.34.56.78. Ip address does not exist in client\'s pool');
is($res->error, '1018: Unable to create hosting on ip 12.34.56.78. Ip address does not exist in client\'s pool');
is($res->errors->[0], '1018: Unable to create hosting on ip 12.34.56.78. Ip address does not exist in client\'s pool');
