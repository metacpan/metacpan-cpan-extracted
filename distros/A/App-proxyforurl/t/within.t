use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'script/proxyforurl not found' unless -e 'script/proxyforurl';
do './script/proxyforurl' or die $@;
my $t = Test::Mojo->new;

$t->get_ok('/within?ip=x&net=y&mask=z')->status_is(400)->content_is('IP or Net is missing.');
$t->get_ok('/within?ip=10.0.0.1&net=10.0.0.0&mask=z')->status_is(400)->content_is('Mask is invalid or missing.');
$t->get_ok('/within?ip=10.0.0.1&net=10.0.0.0&mask=32')->status_is(200)->content_is('0');
$t->get_ok('/within?ip=10.0.0.1&net=10.0.0.0&mask=255.255.255.255')->status_is(200)->content_is('0');
$t->get_ok('/within?ip=10.0.0.1&net=10.0.0.0&mask=20')->status_is(200)->content_is('1');
$t->get_ok('/within?ip=10.0.0.1&net=10.0.0.0&mask=255.255.255.0')->status_is(200)->content_is('1');

done_testing;
