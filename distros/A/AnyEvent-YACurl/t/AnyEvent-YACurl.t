use strict;
use warnings;

use Devel::Peek;
use Test::More tests => 2;
use AnyEvent::YACurl ':constants';

my $cv= AE::cv;
my $cv2= AE::cv;
do {
    my $client= AnyEvent::YACurl->new({
        CURLMOPT_PIPELINING => CURLPIPE_MULTIPLEX
    });
    $client->request(
        $cv,
        {
            CURLOPT_URL => "https://www.tvdw.eu/",
            CURLOPT_VERBOSE => 0,
            CURLOPT_WRITEFUNCTION => sub { },
            CURLOPT_HEADERFUNCTION => sub { warn "Got header: $_[0]"; },
            CURLOPT_SUPPRESS_CONNECT_HEADERS => 1,
            CURLOPT_READFUNCTION => sub { "" },
            CURLOPT_MIMEPOST => [
                { name => "asd", value => "test" },
            ],
        },
    );
    $client->request(
        $cv2,
        {
            CURLOPT_URL => "https://www.google.com",
            CURLOPT_VERBOSE => 0,
            CURLOPT_WRITEFUNCTION => sub { },
        },
    );
};
my ($obj1, $err1)= $cv->recv;
is($obj1->getinfo(CURLINFO_RESPONSE_CODE), 200) or diag $err1;
my ($obj2, $err2)= $cv2->recv;
is($obj2->getinfo(CURLINFO_RESPONSE_CODE), 200) or diag $err2;
