package App::MCP::CLI::Client;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use HTTP::Tiny;
use IO::Handle;
use IPC::Open2;
use JSON::MaybeXS;
use POSIX qw(WNOHANG);
use Scalar::Util qw(blessed);
use Time::HiRes qw(time sleep);

use Exporter 'import';
our @EXPORT_OK = qw(content_text);

use constant PROTOCOL_VERSION => '2024-11-05';

=encoding utf8

=head1 NAME

App::MCP::CLI::Client - Transport-neutral MCP client used by all mcpcli sub-commands

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    use App::MCP::CLI::Client;
    use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

    my ($cmd, $url, $env) = resolve_server_cmd(load_config(), 'my-server');

    my $client = App::MCP::CLI::Client->new(
        cmd     => $cmd,       # stdio transport, or
        url     => $url,       # HTTP/SSE transport
        env     => $env,
        timeout => 30,
    );

    $client->connect;                      # initialize + notifications/initialized
    my $tools = $client->list_tools;       # arrayref of tool descriptors
    my $res   = $client->call_tool('add_numbers', { a => 1, b => 2 });
    print content_text($res->{result}) if $res->{result};
    $client->close;

=head1 DESCRIPTION

C<App::MCP::CLI::Client> hides the differences between the two transports
supported by C<mcpcli> behind one small API, so every sub-command gets the
same behaviour:

=over 4

=item * Every wait for the server is bounded by a timeout (default 30 seconds).

=item * If a stdio server exits unexpectedly, or an SSE stream is closed, a
clear error is raised instead of a JSON parse failure.

=item * Responses are matched to requests by C<id>. Notifications and log
lines sent by the server in between are skipped, and server-initiated
C<ping> requests are answered.

=item * The C<initialize> request is followed by the
C<notifications/initialized> notification, as required by the
C<2024-11-05> lifecycle.

=back

B<stdio>: the server is started with L<IPC::Open2>; messages are
newline-delimited JSON.

B<HTTP/SSE> (protocol revision C<2024-11-05>): a long-lived C<GET> opens the
event stream, the C<endpoint> event announces where to C<POST>, and each
response is accepted either in the C<POST> reply body or as a C<message>
event on the stream. C<https://> URLs need L<IO::Socket::SSL>.

All errors are raised with C<die> and a message ending in a newline.

=head1 METHODS

=head2 new( %args )

Arguments: C<cmd> (arrayref) or C<url> (string); optional C<env> (hashref
applied only to the spawned process), C<timeout> (seconds, C<0> disables),
C<headers> (hashref, SSE only) and C<client_name>.

Set the environment variable C<MCPCLI_DEBUG> to see every JSON-RPC message on
STDERR.

=cut

sub new {
    my ($class, %a) = @_;

    die "Client needs either a command or a URL.\n"
        unless $a{cmd} || defined $a{url};

    return bless {
        cmd     => $a{cmd},
        url     => $a{url},
        env     => $a{env}     || {},
        headers => $a{headers} || {},
        timeout => defined $a{timeout} ? $a{timeout} : 30,
        name    => $a{client_name} // 'mcpcli',
        next_id => 1,
        buf     => '',
        json    => JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1),
    }, $class;
}

=head2 is_sse

True when the client talks HTTP/SSE.

=cut

sub is_sse      { defined $_[0]{url} }

=head2 server_info

The C<serverInfo> hashref reported by the server (after L</connect>).

=cut

sub server_info { $_[0]{server_info} || {} }

sub _deadline {
    my ($self) = @_;
    return time + ($self->{timeout} > 0 ? $self->{timeout} : 1e9);
}

sub _debug {
    my ($self, $dir, $data) = @_;
    return unless $ENV{MCPCLI_DEBUG};
    print STDERR "[mcpcli $dir] $data\n";
}

=head2 connect

Starts the transport and performs the MCP handshake. Returns the client.

=cut

sub connect {
    my ($self) = @_;

    $self->is_sse ? $self->_connect_sse : $self->_connect_stdio;

    my $res = eval { $self->request('initialize', {
        protocolVersion => PROTOCOL_VERSION,
        capabilities    => {},
        clientInfo      => { name => $self->{name}, version => "$VERSION" },
    }) };
    if (my $err = $@) {
        $self->close;
        die $err;
    }
    if ($res->{error}) {
        $self->close;
        die "Server rejected initialize: $res->{error}{message}\n";
    }

    $self->{server_info} = $res->{result}{serverInfo} || {};
    $self->notify('notifications/initialized');

    return $self;
}

=head2 request( $method [, $params] )

Sends a JSON-RPC request and returns the full response hashref (which has
either a C<result> or an C<error> key). Dies on timeout or transport failure.

=cut

sub request {
    my ($self, $method, $params) = @_;

    my $id  = $self->{next_id}++;
    my $msg = { jsonrpc => '2.0', id => $id, method => $method };
    $msg->{params} = $params if defined $params;

    my $deadline = $self->_deadline;
    my $inline   = $self->_send($msg);

    return $inline
        if ref $inline eq 'HASH' && defined $inline->{id} && "$inline->{id}" eq "$id"
        && !exists $inline->{method};

    while (1) {
        my $m = $self->_next_message($deadline, $method);
        next unless ref $m eq 'HASH';

        if (exists $m->{method}) {
            $self->_answer_server_message($m);
            next;
        }

        next unless defined $m->{id} && "$m->{id}" eq "$id";
        return $m;
    }
}

=head2 notify( $method [, $params] )

Sends a JSON-RPC notification (no response is expected).

=cut

sub notify {
    my ($self, $method, $params) = @_;
    my $msg = { jsonrpc => '2.0', method => $method };
    $msg->{params} = $params if defined $params;
    $self->_send($msg);
    return;
}

=head2 list_tools

Returns an arrayref of every tool the server advertises, following
C<nextCursor> pagination. Dies if the server answers with an error.

=cut

sub list_tools {
    my ($self) = @_;

    my (@tools, $cursor);
    my $pages = 0;
    do {
        my $res = $self->request('tools/list',
            defined $cursor ? { cursor => $cursor } : undef);
        die "tools/list failed: $res->{error}{message}\n" if $res->{error};

        push @tools, @{ $res->{result}{tools} // [] };
        $cursor = $res->{result}{nextCursor};
    } while (defined $cursor && length $cursor && ++$pages < 100);

    return \@tools;
}

=head2 call_tool( $name, \%arguments )

Sends C<tools/call> and returns the full response hashref.

=cut

sub call_tool {
    my ($self, $name, $args) = @_;
    return $self->request('tools/call', {
        name      => $name,
        arguments => $args || {},
    });
}

=head2 content_text( $result )

Exported on request. Renders the C<content> blocks of a C<tools/call> result
as text: text blocks are returned verbatim, other block types (image, audio,
resources) become a short placeholder so that nothing is silently dropped.
Falls back to pretty-printed C<structuredContent> when there is no content.

=cut

sub content_text {
    my ($result) = @_;
    return '' unless ref $result eq 'HASH';

    my @out;
    for my $b (@{ $result->{content} // [] }) {
        next unless ref $b eq 'HASH';
        my $type = $b->{type} // '';

        if ($type eq 'text') {
            push @out, $b->{text} // '';
        }
        elsif ($type eq 'image' || $type eq 'audio') {
            push @out, sprintf('[%s: %s, %d bytes base64, not displayed]',
                $type, $b->{mimeType} // 'unknown type', length($b->{data} // ''));
        }
        elsif ($type eq 'resource') {
            my $r = $b->{resource} || {};
            push @out, defined $r->{text}
                ? $r->{text}
                : sprintf('[resource: %s (%s)]', $r->{uri} // '?', $r->{mimeType} // 'unknown type');
        }
        elsif ($type eq 'resource_link') {
            push @out, sprintf('[resource link: %s]', $b->{uri} // '?');
        }
        else {
            push @out, JSON::MaybeXS->new(canonical => 1)->encode($b);
        }
    }

    if (!@out && defined $result->{structuredContent}) {
        push @out, JSON::MaybeXS->new(canonical => 1, pretty => 1)
                                ->encode($result->{structuredContent});
    }

    return join("\n", @out);
}

=head2 close

Shuts the connection down. For stdio servers, stdin is closed first; a server
that has not exited after two seconds is sent C<SIGTERM>, then C<SIGKILL>.
Safe to call more than once.

=cut

sub close {
    my ($self) = @_;
    return if $self->{closed}++;

    if ($self->{sse}) {
        eval { $self->{sse}{sock}->close } if $self->{sse}{sock};
        return;
    }

    return unless $self->{pid};

    eval { CORE::close($self->{in}) };
    my $pid  = $self->{pid};
    my $done = 0;

    for my $grace ([2, 'TERM'], [1, 'KILL']) {
        my $until = time + $grace->[0];
        while (time < $until) {
            my $k = waitpid($pid, WNOHANG);
            if ($k == $pid || $k == -1) { $done = 1; last }
            sleep 0.05;
        }
        last if $done;
        kill $grace->[1], $pid;
    }
    waitpid($pid, 0) unless $done;

    eval { CORE::close($self->{out}) };
    return;
}

sub DESTROY { local ($@, $!, $?); $_[0]->close if $_[0]{pid} || $_[0]{sse} }

# stdio

sub _clean_err {
    my ($e) = @_;
    $e =~ s/ at \S+ line \d+\.?\s*\z//;
    $e =~ s/\s+\z//;
    return "$e\n";
}

sub _connect_stdio {
    my ($self) = @_;

    my ($out, $in);
    my $cmd = $self->{cmd};
    die "No command to start the MCP server.\n" unless $cmd && defined $cmd->[0] && length $cmd->[0];

    # The environment applies to this child only, never to our own process.
    my @keys = keys %{ $self->{env} };
    local @ENV{@keys} = @{ $self->{env} }{@keys};

    my $pid = eval { open2($out, $in, @$cmd) };
    die "Failed to start MCP server '@$cmd': " . _clean_err($@ || $!)
        unless $pid;

    $in->autoflush(1);
    @$self{qw(pid in out)} = ($pid, $in, $out);
    return;
}

sub _read_some {
    my ($fh, $deadline, $what) = @_;

    while (1) {
        unless (blessed($fh) && $fh->can('pending') && $fh->pending) {
            my $left = $deadline - time;
            die "Timed out waiting for $what.\n" if $left <= 0;

            my $rin = '';
            vec($rin, fileno($fh), 1) = 1;
            my $n = select(my $rout = $rin, undef, undef, $left);
            if ($n < 0) {
                next if $!{EINTR};
                die "select failed: $!\n";
            }
            die "Timed out waiting for $what.\n" if $n == 0;
        }

        my $r = sysread($fh, my $chunk, 65536);
        if (!defined $r) {
            next if $!{EINTR} || $!{EAGAIN};
            die "Read error while waiting for $what: $!\n";
        }
        return $r ? $chunk : undef;
    }
}

sub _stdio_message {
    my ($self, $deadline, $what) = @_;

    while (1) {
        if ($self->{buf} =~ s/\A([^\n]*)\n//) {
            my $line = $1;
            $line =~ s/\r\z//;
            next unless $line =~ /\S/;

            $self->_debug('<-', $line);
            my $m = eval { $self->{json}->decode($line) };
            next unless ref $m;    # tolerate stray non-JSON output on stdout
            return $m;
        }

        my $chunk = _read_some($self->{out}, $deadline, "the MCP server's reply to '$what'");
        die "The MCP server closed the connection (did the process exit?).\n"
            unless defined $chunk;
        $self->{buf} .= $chunk;
    }
}

# SSE

sub _parse_url {
    my ($url) = @_;

    $url =~ m{^(https?)://(\[[^\]]+\]|[^/:?#]+)(?::(\d+))?([^#]*)}i
        or die "Invalid URL: $url\n";

    my ($scheme, $host, $port, $path) = (lc $1, $2, $3, $4);
    $path = "/$path" unless $path =~ m{^/};

    my $hostport = $host;
    $hostport .= ":$port" if defined $port;
    (my $bare = $host) =~ s/^\[|\]$//g;

    return {
        scheme => $scheme,
        host   => $bare,
        port   => $port // ($scheme eq 'https' ? 443 : 80),
        path   => $path,
        origin => "$scheme://$hostport",
    };
}

sub _open_socket {
    my ($self, $u) = @_;

    my %opt = (PeerHost => $u->{host}, PeerPort => $u->{port},
               Timeout  => $self->{timeout} > 0 ? $self->{timeout} : 60);
    my $sock;

    if ($u->{scheme} eq 'https') {
        eval { require IO::Socket::SSL; 1 }
            or die "https:// MCP servers need IO::Socket::SSL, which is not installed.\n";
        no warnings 'once';
        $sock = IO::Socket::SSL->new(%opt)
            or die "Cannot connect to $u->{origin}: $IO::Socket::SSL::SSL_ERROR\n";
    }
    else {
        my $class = eval { require IO::Socket::IP; 1 } ? 'IO::Socket::IP'
                  : do { require IO::Socket::INET; 'IO::Socket::INET' };
        $sock = $class->new(%opt)
            or die "Cannot connect to $u->{origin}: " . ($@ || $!) . "\n";
    }

    return $sock;
}

sub _resolve_endpoint {
    my ($base, $ep) = @_;

    $ep =~ s/^\s+|\s+$//g;
    return $ep if $ep =~ m{^https?://}i;

    my $u = _parse_url($base);
    return $u->{origin} . $ep if $ep =~ m{^/};

    (my $dir = $u->{path}) =~ s{[^/]*\z}{};
    return $u->{origin} . $dir . $ep;
}

sub _connect_sse {
    my ($self) = @_;

    my $u        = _parse_url($self->{url});
    my $deadline = $self->_deadline;
    my $sock     = $self->_open_socket($u);

    my $extra = join '', map { "$_: $self->{headers}{$_}\r\n" } sort keys %{ $self->{headers} };
    my $host  = $u->{origin};
    $host =~ s{^https?://}{};

    print {$sock} "GET $u->{path} HTTP/1.1\r\nHost: $host\r\n"
                . "Accept: text/event-stream\r\nCache-Control: no-cache\r\n"
                . "Connection: keep-alive\r\n$extra\r\n"
        or die "Cannot send request to $u->{origin}: $!\n";

    my $raw = '';
    until ($raw =~ /\r?\n\r?\n/) {
        my $chunk = _read_some($sock, $deadline, 'the SSE response headers');
        die "SSE endpoint closed the connection before sending headers.\n"
            unless defined $chunk;
        $raw .= $chunk;
    }
    $raw =~ s/\A(.*?)\r?\n\r?\n//s;
    my @head   = split /\r?\n/, $1;
    my ($code, $reason) = (shift(@head) // '') =~ m{^HTTP/\S+\s+(\d+)\s*(.*)}
        or die "SSE endpoint sent an invalid HTTP response.\n";
    die "Failed to connect to SSE endpoint ($code): $reason\n" unless $code == 200;

    my %h = map { /^([^:]+):\s*(.*)$/ ? (lc $1, $2) : () } @head;

    $self->{sse} = {
        sock      => $sock,
        raw       => $raw,
        text      => '',
        chunked   => (($h{'transfer-encoding'} // '') =~ /chunked/i ? 1 : 0),
        remaining => (exists $h{'content-length'} ? $h{'content-length'} : undef),
        eof       => 0,
    };

    my $ep;
    while (!defined $ep) {
        my $ev = $self->_sse_event($deadline, 'the SSE endpoint event');
        die "SSE stream ended before announcing a POST endpoint.\n" unless $ev;
        $ep = $ev->{data} if $ev->{event} eq 'endpoint';
    }

    $self->{post_url} = _resolve_endpoint($self->{url}, $ep);
    $self->{ua}       = HTTP::Tiny->new(
        timeout => ($self->{timeout} > 0 ? $self->{timeout} : 3600),
    );
    return;
}

sub _sse_decode {
    my ($st) = @_;

    if ($st->{chunked}) {
        while (1) {
            if ($st->{need_crlf}) {
                return if length($st->{raw}) < 2;
                substr($st->{raw}, 0, 2, '');
                $st->{need_crlf} = 0;
            }
            if (!defined $st->{chunk_left}) {
                return unless $st->{raw} =~ s/\A([0-9a-fA-F]+)[^\r\n]*\r\n//;
                $st->{chunk_left} = hex $1;
                if (!$st->{chunk_left}) { $st->{eof} = 1; return }
            }
            return unless length $st->{raw};

            my $take = length($st->{raw}) < $st->{chunk_left}
                     ? length($st->{raw}) : $st->{chunk_left};
            $st->{text}      .= substr($st->{raw}, 0, $take, '');
            $st->{chunk_left} -= $take;
            if (!$st->{chunk_left}) {
                $st->{chunk_left} = undef;
                $st->{need_crlf}  = 1;
            }
        }
    }

    my $n = length $st->{raw};
    $st->{text} .= $st->{raw};
    $st->{raw}   = '';
    if (defined $st->{remaining}) {
        $st->{remaining} -= $n;
        $st->{eof} = 1 if $st->{remaining} <= 0;
    }
    return;
}

sub _sse_event {
    my ($self, $deadline, $what) = @_;
    my $st = $self->{sse};

    while (1) {
        _sse_decode($st) if length $st->{raw};

        # A response with a fixed length (or a terminated chunked body) is a
        # finished stream: release the connection at once so that
        # single-threaded servers can accept our POSTs.
        if ($st->{eof} && !$st->{released}++) {
            eval { $st->{sock}->close };
        }

        if ($st->{text} =~ s/\A(.*?)\r?\n\r?\n//s) {
            my ($event, @data) = ('message');
            for my $line (split /\r?\n/, $1) {
                next if $line =~ /^:/;
                my ($f, $v) = split /:/, $line, 2;
                $v = '' unless defined $v;
                $v =~ s/^ //;
                if    ($f eq 'event') { $event = $v }
                elsif ($f eq 'data')  { push @data, $v }
            }
            next unless @data || $event ne 'message';
            return { event => $event, data => join("\n", @data) };
        }

        return if $st->{eof};

        my $chunk = _read_some($st->{sock}, $deadline, $what);
        if (!defined $chunk) { $st->{eof} = 1; next }
        $st->{raw} .= $chunk;
    }
}

sub _sse_message {
    my ($self, $deadline, $what) = @_;

    while (1) {
        my $ev = $self->_sse_event($deadline, "the MCP server's reply to '$what'")
            or die "The SSE stream was closed before the server replied to '$what'.\n";
        next unless $ev->{event} eq 'message';

        $self->_debug('<-', $ev->{data});
        my $m = eval { $self->{json}->decode($ev->{data}) };
        return $m if ref $m;
    }
}

# shared

sub _next_message {
    my ($self, $deadline, $what) = @_;
    return $self->is_sse
        ? $self->_sse_message($deadline, $what)
        : $self->_stdio_message($deadline, $what);
}

# Sends a message. For SSE, returns the JSON-RPC message found in the POST
# reply body, if any (some servers answer inline instead of on the stream).
sub _send {
    my ($self, $msg) = @_;

    my $raw = $self->{json}->encode($msg);
    $self->_debug('->', $raw);

    if ($self->is_sse) {
        die "The SSE connection is closed.\n" if $self->{closed};
        my $res = $self->{ua}->post($self->{post_url}, {
            headers => { 'content-type' => 'application/json', %{ $self->{headers} } },
            content => $raw,
        });
        unless ($res->{success}) {
            my $detail = $res->{status} == 599 ? " - $res->{content}" : '';
            $detail =~ s/\s+\z//;
            die "MCP HTTP request failed ($res->{status} $res->{reason})$detail\n";
        }

        return unless length($res->{content} // '');
        my $m = eval { $self->{json}->decode($res->{content}) };
        return ref $m eq 'HASH' ? $m : undef;
    }

    die "The MCP server connection is closed.\n" if $self->{closed};
    local $SIG{PIPE} = 'IGNORE';
    my $in = $self->{in};
    print {$in} "$raw\n"
        or die "Failed to write to the MCP server (has it exited?): $!\n";
    return;
}

sub _answer_server_message {
    my ($self, $m) = @_;
    return unless defined $m->{id};    # a notification: nothing to answer

    my $reply = { jsonrpc => '2.0', id => $m->{id} };
    if (($m->{method} // '') eq 'ping') {
        $reply->{result} = {};
    }
    else {
        $reply->{error} = { code => -32601, message => "Method not supported by mcpcli: $m->{method}" };
    }
    eval { $self->_send($reply) };
    return;
}

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI::Config>

=item * L<App::MCP::CLI::Command::call>

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::interactive>

=item * MCP transports: L<https://modelcontextprotocol.io/specification/2024-11-05/basic/transports>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-MCP-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-MCP-CLI/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and / or modify it under
the terms of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of App::MCP::CLI::Client
