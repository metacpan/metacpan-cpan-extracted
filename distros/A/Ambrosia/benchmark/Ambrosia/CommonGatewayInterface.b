#!/usr/bin/perl -w
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Data::Dumper;

BEGIN
{
    use Ambrosia::Context;
    instance Ambrosia::Context({
            engine_name   => 'CGI',
            engine_params => {
                header_params => {
                    Pragma => 'no-cache',
                Cache_Control => 'no-cache, must-revalidate, no-store',
                },
            },
            proxy         => '',
        });

}

sub setEnv
{
    my $action = shift;
    my $query_string = shift;
    $ENV{REQUEST_METHOD} = 'GET';

#generation
    $ENV{DOCUMENT_ROOT} = '/opt/debug.kuritsyn/web/cgi-coll/GOOGLE_COUPON/GoogleCoupon/htdocs';
    $ENV{HTTP_HOST} = 'vh-test-devbillingcoll.domain:8033';
    $ENV{SCRIPT_FILENAME} = '/opt/debug.kuritsyn/web/cgi-coll/GOOGLE_COUPON/GoogleCoupon/htdocs/GoogleCoupon';
    $ENV{SERVER_NAME} = 'vh-test-devbillingcoll.domain';
    $ENV{SERVER_PORT} = '8033';
    $ENV{SERVER_ADDR} = '192.168.14.223';
    $ENV{SCRIPT_NAME} = '/GoogleCoupon';

#parametrize
    $ENV{HTTP_COOKIE} = 'authorize_GOOGLECOUPON=%5EStorable%7C%7C%7Chex%7CCompress%3A%3AZlib%5E789c6365179472cc4d2aca2fce4cb4b20a2dc9cc29b6b272cecf2b49cccc4b2d62626060606201910c2ccc4082118964e2e23534f24c0ad24bf7b2284f2e48060a711424161797e717a570311b1a1903055873f2d333f3800cb1c4d2928cfca2ccaad478777f7f771f5767ffd0007f3fa00c5b7c7c4a62492200c4201edb';
    $ENV{PATH_INFO} = $action;
    $ENV{QUERY_STRING} = $query_string || '';

    $ENV{REQUEST_URI} = $ENV{SCRIPT_NAME} . $ENV{PATH_INFO} . ($ENV{QUERY_STRING} ? '?'.$ENV{QUERY_STRING} : '');
}

sub run
{
    my ($action, $query_string) = @_;
    setEnv($action, $query_string);
    Context->action;
    Context->param('start');
    Context->param('count');
}

##############################################################################################
my $NUM_ITER = 100_000;
timethese($NUM_ITER, {
    '/json/rule/x' => sub {
            run('/json/rule/10', '')
        },
    '/xml/rule/x' => sub {
            run('/xml/rule/10', '')
        },
    '/json/rule' => sub {
            run('/json/rule', 'start=0&count=25')
        },
    '/xml/rule' => sub {
            run('/xml/rule', 'start=0&count=25')
        },

    '/json/coupon' => sub {
            run('/json/coupon', 'start=0&count=25')
        },
    '/xml/coupon' => sub {
            run('/xml/coupon', 'start=0&count=25')
        },
});


