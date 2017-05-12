#!perl
use strict;
use warnings;
use Test::Most;
use FindBin::libs;
use Catalyst::Test 'TestApp';
use HTTP::Request ();
use JSON::XS;
use Data::Printer;

my $ser = JSON::XS->new->utf8;
sub jms_req {
    my ($queue,$type,$body) = @_;

    use bytes;
    my $enc_body=$ser->encode($body);

    my $r = HTTP::Request->new(
        'POST',$queue,
        [
            JMSType => $type,
            'Content-type' => 'application/json',
            'Content-length' => length($enc_body),
        ],
        $enc_body,
    );

    my ($res,$ctx) = ctx_request($r);
    return wantarray ? ($res,$ctx) : $res;
}

my $r = jms_req('/queue/myq','foo',{some=>'thing'});

ok($r->is_success,'request worked');
is($r->content_type,'application/json','content type correct');
my $c = $ser->decode($r->content);
cmp_deeply($c,
           {some=>'thing'},
           'response payload correct') or p $c;

done_testing();
