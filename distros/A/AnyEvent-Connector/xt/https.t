use strict;
use warnings;
use Test::More;
use AnyEvent;
use AnyEvent::Connector;
use AnyEvent::HTTP qw(http_get);

my $ENV_NAME = "PERL_ANYEVENT_CONNECTOR_TEST_PROXY";
my $proxy_url = $ENV{$ENV_NAME};
if(!defined($proxy_url)) {
    plan skip_all => "Set $ENV_NAME environment variable to proxy URL.";
    exit 0;
}

my $conn = AnyEvent::Connector->new(
    proxy => $proxy_url
);

AnyEvent::HTTP::set_proxy undef;

my $cv = AnyEvent->condvar;
http_get "https://www.google.com/", tcp_connect => sub { $conn->tcp_connect(@_) }, sub {
    my ($data, $headers) = @_;
    $cv->send($data, $headers);
};
my ($data, $headers) = $cv->recv;
like $headers->{Status}, qr/^2\d\d$/, "successful status";
isnt $data, "", "non-empty data";

done_testing;


