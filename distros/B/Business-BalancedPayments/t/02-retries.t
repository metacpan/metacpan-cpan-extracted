use Test::Modern;

use Business::BalancedPayments;
use HTTP::Response;
use JSON qw(to_json);
use Test::Mock::LWP::Dispatch;

subtest 'Retry multiple times' => sub {
    my $ua = LWP::UserAgent->new();
    my $bp = Business::BalancedPayments->client(
        version => 1, secret => 9, retries => 2, ua => $ua);
    my $url = $bp->base_url . '/v1/marketplaces';
    my $num_tries = 0;
    $ua->map($url => sub { $num_tries++; return HTTP::Response->new(500) });
    ok exception { $bp->marketplace };
    is $num_tries => 3, 'Tried 3 times';
};

subtest 'Retry and succeed' => sub {
    my $ua = LWP::UserAgent->new();
    my $bp = Business::BalancedPayments->client(
        version => 1, secret => 9, retries => 2, ua => $ua);
    my $url = $bp->base_url . '/v1/marketplaces';
    my $num_tries = 0;
    $ua->map($url => sub {
        if ($num_tries++) {
            return HTTP::Response->new(200, '', [], to_json {
                items => [ { foo => 'bar' } ]
            });
        }
        return HTTP::Response->new(500);
    });
    is $bp->marketplace->{foo} => 'bar';
    is $num_tries => 2, 'Tried 2 times and succeeded on the second try';
};

subtest 'No retries' => sub {
    my $ua = LWP::UserAgent->new();
    my $bp = Business::BalancedPayments->client(
        version => 1, secret => 9, ua => $ua);
    my $url = $bp->base_url . '/v1/marketplaces';
    my $num_tries = 0;
    $ua->map($url => sub { $num_tries++; return HTTP::Response->new(500) });
    ok exception { $bp->marketplace };
    is $num_tries => 1, 'Tried once';
};

done_testing;
