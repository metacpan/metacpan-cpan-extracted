# test socker destroy by setting limit to number of open files
use strict;
use Test::More;
use AnyEvent;

BEGIN {
    eval "use BSD::Resource qw(getrlimit setrlimit RLIMIT_NOFILE)";
    if ($@) {
        plan skip_all => "BSD::Resource required for test";
        exit 0;
    }
    use_ok("AnyEvent::Radius::Client") || exit 1;
    use_ok("AnyEvent::Radius::Server") || exit 1;
};

use constant {
    AV_USERNAME => 1,
    AV_PASSWORD => 2,
    AV_REPLY_MSG => 18,

    DISCONNECT_ACCEPT => 41,
};

my $ip = '127.0.0.1';
my $port = 32000 + int(rand(32000));
my $secret = 'very-random-string';

my $child = fork();
if ($child) {
    # request to server
    sleep 1;

    my $requests = 100;

    # max allowed number of open files
    my $file_limit = getrlimit(RLIMIT_NOFILE);
    if (!$file_limit || $file_limit > $requests) {
        setrlimit(RLIMIT_NOFILE, 50, 50);
    }

    my $replies = 0;

    foreach my $i (1 .. $requests) {
        my $nas = AnyEvent::Radius::Client->new(
                ip => $ip,
                port => $port,
                on_read => sub { $replies++ },
                secret => $secret,
            );
        $nas->send_pod([
                {Id => AV_USERNAME, Name => 'User-Name', Type => 'string', Value => 'chip'},
            ]);
        $nas->wait();
        AnyEvent::postpone { $nas->destroy };
    }

    diag "Killing server $child";
    kill('KILL', $child);

    is($requests, $replies, 'all replies received');
}
elsif(defined $child) {
    # starts server
    my $radius_reply = sub {
        my ($self, $h) = @_;
        return (DISCONNECT_ACCEPT, [{Id => AV_REPLY_MSG, Name => 'Reply-Message', Type => 'string', Value => 'TEST'}]);
    };

    my $server = AnyEvent::Radius::Server->new(
                        ip => $ip,
                        port => $port,
                        secret => $secret,
                        on_read => $radius_reply,
                    );
    diag "Server $$ listen on $ip:$port";

    AnyEvent->condvar->recv;
}
else {
    fail("fork failed");
}

done_testing;
