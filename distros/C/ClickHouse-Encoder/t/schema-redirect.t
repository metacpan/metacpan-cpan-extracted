use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# Keep Enum literals intact and avoid forwarding credentials on redirects.

# Enum label with an unbalanced paren: type must survive verbatim and
# later columns must not be dropped.
{
    my $ddl = q{CREATE TABLE t (`a` Enum8('x)y' = 1, 'z' = 2), b UInt32) ENGINE = Memory};
    my $s = ClickHouse::Encoder->parse_create_table($ddl);
    is_deeply($s->{columns},
        [['a', q{Enum8('x)y' = 1, 'z' = 2)}], ['b', 'UInt32']],
        'paren in Enum label keeps type and later columns');
    is($s->{engine}, 'Memory', 'engine still parsed after Enum fix');
}

# Both ClickHouse literal-escape forms shield their quotes.
{
    my $ddl = q{CREATE TABLE t (a Enum8('it''s (x' = 1), b Int8) ENGINE = Memory};
    my $s = ClickHouse::Encoder->parse_create_table($ddl);
    is_deeply($s->{columns},
        [['a', q{Enum8('it''s (x' = 1)}], ['b', 'Int8']],
        "doubled-quote escape survives parse");
    $ddl = q{CREATE TABLE t (a Enum8('it\'s (x' = 1), b Int8) ENGINE = Memory};
    $s = ClickHouse::Encoder->parse_create_table($ddl);
    is(scalar @{$s->{columns}}, 2, 'backslash-quote escape keeps column count');
    is($s->{columns}[1][0], 'b', 'column after backslash-escaped label kept');
}

# Sibling splitter: Enum comma inside Nested/Tuple type lists.
{
    my $flat = ClickHouse::Encoder->flatten_nested(
        [['n', q{Nested(x UInt8, y Enum8('p,q' = 2))}]]);
    is_deeply($flat, [['n.x', 'Array(UInt8)'], ['n.y', q{Array(Enum8('p,q' = 2))}]],
        'comma in Enum label does not split Nested elements');
}

my $can_fork = $Config{d_fork} && $Config{d_fork} eq 'define';

SKIP: {
    skip 'fork unavailable', 3 unless $can_fork;
    my $has_sock = eval { require IO::Socket::INET; require IO::Select; 1 };
    skip 'IO::Socket::INET unavailable', 3 unless $has_sock;

    # Redirector on port A 302s to target on port B (cross-origin by
    # port). Target records any X-ClickHouse-Key it sees into $seen.
    my $dir = tempdir(CLEANUP => 1);
    my $seen = "$dir/seen.txt";
    my $srv_a = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:0', Listen => 5, ReuseAddr => 1);
    my $srv_b = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:0', Listen => 5, ReuseAddr => 1);
    skip 'cannot bind loopback sockets', 3 unless $srv_a && $srv_b;
    my ($pa, $pb) = ($srv_a->sockport, $srv_b->sockport);
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        close STDOUT;
        my $c = $srv_a->accept;
        my $req = '';
        $c->recv($req, 65536);
        print $c "HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:$pb/\r\n"
            . "Content-Length: 0\r\nConnection: close\r\n\r\n";
        close $c;
        if (IO::Select->new($srv_b)->can_read(5)) {
            $c = $srv_b->accept;
            $req = '';
            $c->recv($req, 65536);
            my ($key) = $req =~ /^X-ClickHouse-Key:\s*(.*)$/mi;
            open my $fh, '>', $seen or exit 1;
            print $fh defined $key ? "hit:$key" : 'hit:';
            close $fh;
            print $c "HTTP/1.1 200 OK\r\nContent-Length: 6\r\n"
                . "Connection: close\r\n\r\n24.8.1\n";
            close $c;
        }
        exit 0;
    }
    close $_ for ($srv_a, $srv_b);
    sleep 1;
    local $@;
    eval {
        ClickHouse::Encoder->server_version(
            host => '127.0.0.1', port => $pa,
            password => 's3cret', timeout => 10);
    };
    like($@, qr/status 302/, 'redirect is surfaced, not followed');
    waitpid $pid, 0;
    my $got = '';
    if (open my $fh, '<', $seen) { $got = <$fh> // ''; close $fh }
    is($got, '', 'redirect target never contacted (no key leak)');
    unlike($got, qr/s3cret/, 'password not forwarded cross-origin');
}

done_testing();
