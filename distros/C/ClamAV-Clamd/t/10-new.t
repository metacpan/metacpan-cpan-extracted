use strict;
use warnings;
use Test::More;
use ClamAV::Clamd;

# Configuration that cannot work croaks. A clamd that went away does not
# - that split is deliberate and phase 1 owns it.

like exception(sub { ClamAV::Clamd->new() }),
    qr/one of 'socket' or 'host'/,
    'no address croaks';

like exception(sub { ClamAV::Clamd->new('socket') }),
    qr/key => value pairs/,
    'an odd-length argument list croaks';

like exception(sub { ClamAV::Clamd->new(socket => '/x', host => 'y') }),
    qr/not both/,
    'both addresses croaks';

like exception(sub { ClamAV::Clamd->new(host => 'x', connect_timeout => 0) }),
    qr/must be a positive number/,
    'zero connect_timeout croaks';

like exception(sub { ClamAV::Clamd->new(host => 'x', reply_timeout => -1) }),
    qr/must be a positive number/,
    'negative reply_timeout croaks';

like exception(sub { ClamAV::Clamd->new(host => 'x', frame => 'q') }),
    qr/frame must be/,
    'bad framing croaks';

# The one that matters: an over-long UNIX path is REFUSED, not truncated.
# A truncated sun_path connects to a different socket than the one
# configured, and believing an answer from an unknown peer is worse than
# not getting one.
SKIP: {
    my $max = ClamAV::Clamd::_sun_path_max();
    skip 'no UNIX sockets on this platform', 2 unless $max;

    cmp_ok $max, '>=', 92, "sockaddr_un holds at least 92 bytes (this platform: $max)";

    my $long = '/tmp/' . ('x' x $max) . '.sock';
    like exception(sub { ClamAV::Clamd->new(socket => $long) }),
        qr/socket path is \d+ bytes, this platform allows \d+/,
        'over-long socket path croaks instead of truncating';
}

ok +ClamAV::Clamd->new(socket => '/tmp/whatever.sock'), 'a plausible socket path constructs';
ok +ClamAV::Clamd->new(host => '127.0.0.1'), 'host constructs, port defaults';

is +ClamAV::Clamd->new(host => 'x')->{port}, 3310, 'default port is 3310';

# new() does not connect, so a dead address is fine until a command runs.
ok +ClamAV::Clamd->new(socket => '/nonexistent/clamd.sock'),
    'new does not connect';

sub exception {
    my ($code) = @_;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return defined $err ? $err : '';
}

done_testing;
