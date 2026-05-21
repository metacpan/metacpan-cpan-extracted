use strict;
use warnings;

use Test::More tests => 14 + 1;
use Test::MockModule;
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius') };

# Verify Message-Authenticator (RFC 3579) is added to Access-Request by
# default (Blast-RADIUS mitigation), is placed as the first attribute per
# RFC 9716 section 4.2, can be disabled with Rfc3579MessageAuth => 0, and that
# the HMAC-MD5 value matches an independent reference computation.

my $MSG_AUTH_ATTR_ID  = 80;
my $MSG_AUTH_ATTR_LEN = 18;

# Capture the wire packet instead of actually sending it.
sub capture_wire {
    my (%args) = @_;
    my $secret = $args{Secret} // 'testing123';
    my %opts   = (
        Host    => '127.0.0.1',
        Secret  => $secret,
        TimeOut => 1,
        %{ $args{Opts} // {} },
    );

    my $r = Authen::Radius->new(%opts);
    die 'object creation failed' unless $r;

    # Deterministic authenticator so the HMAC computation is reproducible.
    $r->{authenticator} = "\x00" x 16;
    # Pre-built User-Name = "alice" attribute (type 1, length 7, value "alice").
    $r->{attributes}    = pack('C C', 1, 7) . 'alice';

    my $captured;
    my $sock_mock = Test::MockModule->new('IO::Socket::INET');
    $sock_mock->mock(send => sub {
        my ($self, $data) = @_;
        $captured = $data;
        return length($data);
    });

    $r->send_packet(Authen::Radius::ACCESS_REQUEST());
    return ($r, $captured);
}

# Locate an attribute by type id inside a captured RADIUS packet body.
# Returns the value bytes, or undef when the attribute is not present.
sub find_attr {
    my ($packet, $wanted_id) = @_;
    my $body = substr($packet, 20);    # skip code(1)+id(1)+length(2)+auth(16)
    my $i = 0;
    while ($i + 2 <= length($body)) {
        my ($t, $l) = unpack('C C', substr($body, $i, 2));
        return undef if $l < 2 || $i + $l > length($body);
        return substr($body, $i + 2, $l - 2) if $t == $wanted_id;
        $i += $l;
    }
    return undef;
}

# --- Default: Message-Authenticator must be present ---------------------
{
    my ($r, $pkt) = capture_wire();
    ok(defined $pkt, 'Access-Request was captured (default settings)');

    my $msg_auth = find_attr($pkt, $MSG_AUTH_ATTR_ID);
    ok(defined $msg_auth,
        'Message-Authenticator present by default (Blast-RADIUS mitigation)');
    is(length($msg_auth), $MSG_AUTH_ATTR_LEN - 2,
        'Message-Authenticator value is 16 bytes');
    isnt($msg_auth, "\x00" x 16,
        'Message-Authenticator is filled in, not left as the placeholder');

    # RFC 9716 section 4.2: SHOULD be the first attribute in Access-Request.
    my ($first_type, $first_len) = unpack('C C', substr($pkt, 20, 2));
    is($first_type, $MSG_AUTH_ATTR_ID,
        'Message-Authenticator is the first attribute (RFC 9716 sec 4.2)');
    is($first_len, $MSG_AUTH_ATTR_LEN,
        'first attribute declares the expected length');

    # Recompute HMAC-MD5 over the packet with the Message-Authenticator
    # value zeroed out, and confirm it matches what the client sent.
    my $zeroed = $pkt;
    my $offset = index($pkt, pack('C C', $MSG_AUTH_ATTR_ID, $MSG_AUTH_ATTR_LEN));
    substr($zeroed, $offset + 2, 16) = "\x00" x 16;
    my $expected = $r->hmac_md5($zeroed, 'testing123');
    is($msg_auth, $expected,
        'Message-Authenticator equals HMAC-MD5(packet-with-zeroed-MA, secret)');
}

# --- Opt-out: Rfc3579MessageAuth => 0 must NOT add the attribute --------
{
    my (undef, $pkt) = capture_wire(Opts => { Rfc3579MessageAuth => 0 });
    ok(defined $pkt, 'Access-Request was captured (opt-out)');
    is(find_attr($pkt, $MSG_AUTH_ATTR_ID), undef,
        'no Message-Authenticator when Rfc3579MessageAuth => 0');
}

# --- Explicit Rfc3579MessageAuth => 1 still works -----------------------
{
    my (undef, $pkt) = capture_wire(Opts => { Rfc3579MessageAuth => 1 });
    ok(defined find_attr($pkt, $MSG_AUTH_ATTR_ID),
        'Message-Authenticator present with explicit Rfc3579MessageAuth => 1');
}

# --- NodeList (cluster) path: every per-node send must carry MA ---------
# When NodeList is used without Host, send_packet creates a socket per node
# and calls send() on each. Verify the framing change still puts
# Message-Authenticator first on every transmitted copy.
{
    my @nodes = ('127.0.0.1:1820', '127.0.0.2:1830');
    my $r = Authen::Radius->new(
        NodeList => \@nodes,
        Secret   => 'testing123',
        TimeOut  => 1,
    );
    ok($r, 'object created with NodeList');

    $r->{authenticator} = "\x00" x 16;
    $r->{attributes}    = pack('C C', 1, 7) . 'alice';

    my @captured;
    my $sock_mock = Test::MockModule->new('IO::Socket::INET');
    $sock_mock->mock(send => sub {
        my ($self, $data) = @_;
        push @captured, $data;
        return length($data);
    });

    $r->send_packet(Authen::Radius::ACCESS_REQUEST());

    is(scalar(@captured), scalar(@nodes),
        'send_packet transmitted one packet per cluster node');

    my $all_first = 1;
    for my $pkt (@captured) {
        my ($t) = unpack('C', substr($pkt, 20, 1));
        $all_first = 0 if $t != $MSG_AUTH_ATTR_ID;
    }
    ok($all_first,
        'Message-Authenticator is the first attribute in every cluster send');
}
