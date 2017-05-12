use strict;
use warnings;
use Test::Spec;
use Browsermob::Server;

SKIP: {
    my $server = Browsermob::Server->new;
    my $has_connection = IO::Socket::INET->new(
        PeerAddr => 'www.google.com',
        PeerPort => 80,
        Timeout => 5
    );

    skip 'No server found for e2e tests', 2
      unless $server->_is_listening(5) and $has_connection;

    describe 'Simple E2E test' => sub {
        my ($ua, $proxy, $har);

        before each => sub {
            $ua = LWP::UserAgent->new;
            $proxy = $server->create_proxy;
            $ua->proxy($proxy->ua_proxy);
            $ua->get('http://www.google.com');

            $har = $proxy->har;
        };

        it 'should contain a GET entry to google' => sub {
            $har = $proxy->har;
            my $entry = $har->{log}->{entries}->[0];

            like($entry->{request}->{url}, qr{http://www\.google\.com});
            is($entry->{request}->{method}, 'GET' );
        };
    };
}

runtests;
