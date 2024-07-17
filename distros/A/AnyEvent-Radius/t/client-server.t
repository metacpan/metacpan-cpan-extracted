use strict;
use Test::More;
use AnyEvent;
use English qw( -no_match_vars );

BEGIN {
    if ($OSNAME eq 'MSWin32') {
        plan skip_all => 'Skip tests for MSWin32 due to used fork()';
        exit 0;
    }

    use_ok("AnyEvent::Radius::Client") || exit 1;
    use_ok("AnyEvent::Radius::Server") || exit 1;
};

use constant {
    AV_USERNAME => 1,
    AV_PASSWORD => 2,
    AV_REPLY_MSG => 18,
    AV_ACCT_STATUS => 40,

    AUTH_REQ => 1,
    AUTH_OK  => 2,
    AUTH_REJ => 3,
    ACCT_REQ => 4,
    ACCT_OK  => 5,
};

my $ip = '127.0.0.1';
my $port = 32000 + int(rand(32000));
my $secret = 'very-random-string';

my $child = fork();
if ($child) {
    # request to server
    sleep 1;

    my $replies = 0;
    my %user = ();
    my $radius_reply = sub {
        my ($self, $h) = @_;
        $replies++;

        my $login = $user{ $h->{request_id} };
        ok($login, 'reply to our request');

        if ($login eq 'chip') {
            ok($h->{type} == AUTH_OK, 'Chip auth ok');
        }
        elsif ($login eq 'dale') {
            ok($h->{type} == AUTH_REJ, 'Dale not allowed');
        }
        elsif ($login eq '[acct]') {
            ok($h->{type} == ACCT_OK, 'Accounting reply');
        }
        else {
            fail('unexpected reply');
        }
    };

    my $nas = AnyEvent::Radius::Client->new(
                    ip => $ip,
                    port => $port,
                    secret => $secret,
                    on_read => $radius_reply,
                );

    my $id = $nas->send_auth([
                {Id => AV_USERNAME, Name => 'User-Name', Type => 'string', Value => 'chip'},
                {Id => AV_PASSWORD, Name => 'Password', Type => 'string', Value => 'pwd'},
            ]);
    $user{$id} = 'chip';
    $id = $nas->send_auth([
                {Id => AV_USERNAME, Name => 'User-Name', Type => 'string', Value => 'dale'},
                {Id => AV_PASSWORD, Name => 'Password', Type => 'string', Value => 'pwd'},
            ]);
    $user{$id} = 'dale';
    $id = $nas->send_acct([
                {Id => AV_ACCT_STATUS, Name => 'Acct-Status-Type', Type => 'integer', Value => 1 },
            ]);
    $user{$id} = '[acct]';

    $nas->wait;
    diag "Killing server $child";
    kill('KILL', $child);

    is($replies, 3, 'got 3 replies from server');
}
elsif(defined $child) {
    # starts server
    my $radius_reply = sub {
        my ($self, $h) = @_;

        if ($h->{type} eq ACCT_REQ) {
            return (ACCT_OK, []);
        }

        return undef if ($h->{type} != AUTH_REQ);

        foreach my $av (@{ $h->{av_list} }) {
            # ID is stored to Name when dictionary not used
            if ($av->{Name} == AV_USERNAME) {
                if($av->{Value} eq 'chip') {
                    return (AUTH_OK, [{Id => AV_REPLY_MSG, Name => 'Reply-Message', Type => 'string', Value => 'Allowed'}]);
                }
                else {
                    return (AUTH_REJ, [{Id => AV_REPLY_MSG, Name => 'Reply-Message', Type => 'string', Value => 'Access denied'}]);
                }
            }
        }

        return (AUTH_REJ, [{Id => AV_REPLY_MSG, Name => 'Reply-Message', Type => 'string', Value => 'No Username - rejected'}]);
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
