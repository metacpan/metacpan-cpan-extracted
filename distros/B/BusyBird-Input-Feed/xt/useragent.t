use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use BusyBird::Input::Feed;

if(!$ENV{BB_INPUT_FEED_NETWORK_TEST}) {
    plan('skip_all', "Set BB_INPUT_FEED_NETWORK_TEST environment to enable the test");
    exit;
}

my @request_log = ();
my @agents = ();
my $useragent = do {
    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy;
    $lwp->agent('HOGEHOGE-UA');
    $lwp->add_handler(request_send => sub {
        my ($request) = @_;
        push @request_log, $request;
        my $ua_header = $request->header('User-Agent');
        push @agents, $ua_header if defined $ua_header;
        return;
    });
    $lwp;
};

my $input = BusyBird::Input::Feed->new(user_agent => $useragent);
my $statuses = $input->parse_url('https://metacpan.org/feed/recent?f=');
cmp_ok scalar(@$statuses), '>', 0, 'at least 1 statuses loaded';
cmp_ok scalar(@request_log), '>', 0, 'communication logged.';
cmp_ok scalar(grep { $_->uri eq 'https://metacpan.org/feed/recent?f=' } @request_log), '>', 0, 'logged fetching feed URL';
cmp_ok scalar(grep { $_->uri eq 'https://metacpan.org/' } @request_log), '>', 0, 'logged fetching main URL';
cmp_ok scalar(grep { $_->uri =~ qr/favicon\.ico/ } @request_log), '>', 0, 'logged fetching favicon';

is scalar(@agents), scalar(@request_log), 'same number of User-Agent logs as that requests';

my @unexpected_useragents = grep { $_ ne 'HOGEHOGE-UA' } @agents;
is scalar(@unexpected_useragents), 0, 'User-Agent is not changed by the module.' or do {
    diag("Unexpected User-Agents:");
    diag($_) for @unexpected_useragents;
};

done_testing;
