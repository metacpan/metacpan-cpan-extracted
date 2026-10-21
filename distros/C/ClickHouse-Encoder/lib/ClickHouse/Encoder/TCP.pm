package ClickHouse::Encoder::TCP;  ## no critic (Capitalization)
use strict;
use warnings;

our $VERSION = '0.03';

# Encoders/decoders for a useful subset of ClickHouse's native TCP
# protocol packets. Built for insert pipelines: pack a Hello + Query,
# then wrap encoded Native blocks in Data packets, then signal
# end-of-insert. Transport is the caller's job (IO::Socket,
# AnyEvent::Handle, IO::Async::Stream, etc.).
#
# Varint and length-prefixed string codecs are XS (shared with the
# main encoder's buffer helpers); packet-level layout stays in Perl
# for readability since it's not a hot path.
#
# Targets negotiated revision 54429; newer fields require a full client.

# XS loader handled by the parent module; ensure it's loaded so the
# XSUBs under PACKAGE = ClickHouse::Encoder::TCP are available.
use ClickHouse::Encoder ();
use Errno ();

## no critic (ProhibitConstantPragma)
# Readability beats Readonly here - these are protocol-defined
# numeric tags, used as bare identifiers throughout the module.
use constant DEFAULT_REVISION => 54429;

# Client packet types
use constant CLIENT_HELLO  => 0;
use constant CLIENT_QUERY  => 1;
use constant CLIENT_DATA   => 2;
use constant CLIENT_CANCEL => 3;
use constant CLIENT_PING   => 4;

# Server packet types
use constant SERVER_HELLO          => 0;
use constant SERVER_DATA           => 1;
use constant SERVER_EXCEPTION      => 2;
use constant SERVER_PROGRESS       => 3;
use constant SERVER_PONG           => 4;
use constant SERVER_END_OF_STREAM  => 5;
use constant SERVER_PROFILE_INFO   => 6;
use constant SERVER_TOTALS         => 7;
use constant SERVER_EXTREMES       => 8;
use constant SERVER_LOG            => 10;
use constant SERVER_TABLE_COLUMNS  => 11;
use constant SERVER_PROFILE_EVENTS => 14;

# Query processing stages
use constant STAGE_FETCH_COLUMNS      => 0;
use constant STAGE_WITH_MERGEABLE     => 1;
use constant STAGE_COMPLETE           => 2;

# Compression flags in Query packet
use constant COMPRESSION_DISABLE => 0;
use constant COMPRESSION_ENABLE  => 1;

# Varint and length-prefixed string codecs are XS-backed; the bound
# subs (pack_varint, unpack_varint, pack_string, unpack_string)
# live in PACKAGE = ClickHouse::Encoder::TCP inside Encoder.xs.

# ----- client packets ------------------------------------------------

# Hello packet: announces our protocol revision and credentials.
#
#   pack_hello(
#       client_name => 'ClickHouse::Encoder',  # default
#       major       => 1,                       # default
#       minor       => 0,                       # default
#       revision    => 54429,                   # default
#       database    => 'default',
#       user        => 'default',
#       password    => '',
#   );
sub pack_hello {
    my (undef, %o) = @_;
    return pack_varint(CLIENT_HELLO)
         . pack_string($o{client_name} // 'ClickHouse::Encoder')
         . pack_varint($o{major}    // 1)
         . pack_varint($o{minor}    // 0)
         . pack_varint($o{revision} // DEFAULT_REVISION)
         . pack_string($o{database} // 'default')
         . pack_string($o{user}     // 'default')
         . pack_string($o{password} // '');
}

# Query packet. At revision 54429 the body is:
#   varint  CLIENT_QUERY (=1)
#   string  query_id (often empty so the server generates one)
#   <ClientInfo>      (block - see _pack_client_info)
#   <Settings>        (see _pack_settings)
#   varint  query_processing_stage (default Complete)
#   varint  compression flag (default Disable)
#   string  query SQL text
sub pack_query {
    my (undef, %o) = @_;
    my $rev = $o{revision} // DEFAULT_REVISION;
    return pack_varint(CLIENT_QUERY)
         . pack_string($o{query_id} // '')
         . ($rev >= 54032 ? _pack_client_info(\%o) : '')
         . _pack_settings($o{settings})
         . pack_varint($o{stage} // STAGE_COMPLETE)
         . pack_varint($o{compression} // COMPRESSION_DISABLE)
         . pack_string($o{query} // die "pack_query: 'query' is required\n")
         . __PACKAGE__->pack_data_end(revision => $rev,
             compress => $o{compression} ? ($o{compress} // 'lz4') : 'raw');
}

# ClientInfo subblock. At revision 54429 the fields after the
# fixed prefix are: quota_key (since 54058), version_patch (since
# 54401). We use those defaults; later-revision fields (interserver
# secret, OpenTelemetry trace context, parallel-replica metadata)
# would need a higher client revision to be negotiated.
sub _pack_client_info {
    my $o = shift;
    my $rev = $o->{revision} // DEFAULT_REVISION;
    my $out = '';
    my $kind = $o->{query_kind} // 1;
    return chr(0) if !$kind;
    $out .= chr($kind);   # 1 = initial query

    $out .= pack_string($o->{initial_user}     // '');
    $out .= pack_string($o->{initial_query_id} // '');
    $out .= pack_string($o->{initial_address}  // '0.0.0.0:0');
    # interface: 1 = TCP
    $out .= chr(1);
    # os_user, client_hostname, client_name
    $out .= pack_string($o->{os_user}         // '');
    $out .= pack_string($o->{client_hostname} // 'localhost');
    $out .= pack_string($o->{client_name}     // 'ClickHouse::Encoder');
    # client_version_{major,minor}, client_revision
    $out .= pack_varint($o->{client_version_major} // 1);
    $out .= pack_varint($o->{client_version_minor} // 0);
    $out .= pack_varint($o->{client_revision}      // $rev);
    # quota_key (rev >= 54058)
    $out .= pack_string($o->{quota_key} // '') if $rev >= 54058;
    # client_version_patch (rev >= 54401)
    $out .= pack_varint($o->{client_version_patch} // 0)
        if $rev >= 54401;
    return $out;
}

# Settings block. At revision >= 54429 each entry is:
#   string name + varint flags + string value
# terminated by an empty-key string. flags is a bitmask where 0 means
# "ordinary setting"; bit 0x01 = IMPORTANT, bit 0x02 = CUSTOM. We
# always emit flags=0 - the server still accepts any setting at flag 0.
sub _pack_settings {
    my $s = shift;
    return pack_string('') unless defined $s;
    if (ref $s eq 'HASH') {
        my $body = '';
        for my $k (sort keys %$s) {
            $body .= pack_string($k);
            $body .= pack_varint(0);          # flags: ordinary
            $body .= pack_string($s->{$k});
        }
        $body .= pack_string('');             # end marker
        return $body;
    }
    # Allow caller to pass raw bytes (already in the right shape).
    return $s;
}

# Data packet wrapping a Native block. table_name is usually empty
# for inserts; the server already knows the target from the Query.
# With compress => 'lz4' (or 'zstd') the block is wrapped in CH's
# compressed-block framing (16-byte CityHash128 + 9-byte header +
# compressed payload) before being placed on the wire; the server
# must have been told to expect compressed data via the Query packet's
# compression flag (see pack_query's `compression =E<gt>
# COMPRESSION_ENABLE`).
sub pack_block_info { return "\x01\x00\x02\xff\xff\xff\xff\x00" }

sub unpack_block_info {
    my ($bytes, $offset) = @_;
    my %info;
    while (1) {
        (my $field, $offset) = unpack_varint($bytes, $offset);
        last if !$field;
        my $width = $field == 1 ? 1 : $field == 2 ? 4 : 0;
        die "BlockInfo: unknown field $field\n" unless $width;
        die "BlockInfo: truncated at offset $offset\n" if $offset + $width > length $bytes;
        $info{$field == 1 ? 'is_overflows' : 'bucket_num'} = $field == 1
            ? ord substr($bytes, $offset, 1)
            : unpack('l<', substr($bytes, $offset, 4));
        $offset += $width;
    }
    return (\%info, $offset);
}

sub pack_data {
    my (undef, $block_bytes, %o) = @_;
    die "pack_data: block bytes required\n" unless defined $block_bytes;
    my $rev = $o{revision} // DEFAULT_REVISION;
    $block_bytes = pack_block_info() . $block_bytes if $rev >= 51903;
    if (defined $o{compress} && $o{compress} ne 'none' && $o{compress} ne 'raw') {
        $block_bytes = ClickHouse::Encoder->compress_native_block($block_bytes, mode => $o{compress});
    }
    return pack_varint(CLIENT_DATA)
         . ($rev >= 50264 ? pack_string($o{table_name} // '') : '')
         . $block_bytes;
}

sub pack_data_end {
    my ($class, %o) = @_;
    return $class->pack_data("\x00\x00", %o);
}

sub pack_ping {
    return pack_varint(CLIENT_PING);
}

sub pack_cancel {
    return pack_varint(CLIENT_CANCEL);
}

# ----- server packet decoder -----------------------------------------

# Parse one server packet from $bytes starting at $offset. Returns
# (\%packet, $new_offset). %packet always has 'type' (numeric);
# payload fields depend on type. Croaks on truncation; caller can
# pre-screen by ensuring at least 1 byte is available.
sub unpack_packet {
    my (undef, $bytes, $offset, %opts) = @_;
    $offset //= 0;
    (my $type, $offset) = unpack_varint($bytes, $offset);
    my %pkt = (type => $type);
    my $rev = $opts{revision} // DEFAULT_REVISION;
    if ($type == SERVER_HELLO) {
        ($pkt{name},     $offset) = unpack_string($bytes, $offset);
        ($pkt{major},    $offset) = unpack_varint($bytes, $offset);
        ($pkt{minor},    $offset) = unpack_varint($bytes, $offset);
        ($pkt{revision}, $offset) = unpack_varint($bytes, $offset);
        # Newer revisions add timezone / display_name / version_patch.
        # Gate on the revision the server just reported, not on "are
        # there bytes left": a buffer that ends mid-Hello must croak
        # 'truncated' so the reader fetches more, not silently drop a
        # field whose bytes simply have not arrived yet. Thresholds
        # match ClickHouse's DBMS_MIN_REVISION_WITH_* constants.
        my $hello_rev = $pkt{revision} < $rev ? $pkt{revision} : $rev;
        if ($hello_rev >= 54058) {
            ($pkt{timezone}, $offset)
                = unpack_string($bytes, $offset);
        }
        if ($hello_rev >= 54372) {
            ($pkt{display_name}, $offset)
                = unpack_string($bytes, $offset);
        }
        if ($hello_rev >= 54401) {
            ($pkt{version_patch}, $offset)
                = unpack_varint($bytes, $offset);
        }
    }
    elsif ($type == SERVER_EXCEPTION) {
        # ExceptionPacket: code(Int32 LE), name, message, stack_trace, has_nested(byte)
        die "unpack_packet: truncated at offset $offset"
            if $offset + 4 > length $bytes;
        $pkt{code} = unpack 'l<', substr($bytes, $offset, 4);
        $offset += 4;
        ($pkt{name},        $offset) = unpack_string($bytes, $offset);
        ($pkt{message},     $offset) = unpack_string($bytes, $offset);
        ($pkt{stack_trace}, $offset) = unpack_string($bytes, $offset);
        die "unpack_packet: truncated at offset $offset"
            if $offset >= length $bytes;
        $pkt{has_nested} = ord substr($bytes, $offset++, 1);
        if ($pkt{has_nested}) {
            my ($nested, $next) = __PACKAGE__->unpack_packet(
                pack_varint(SERVER_EXCEPTION) . substr($bytes, $offset));
            $pkt{nested} = $nested;
            $offset += $next - 1;
        }
    }
    elsif ($type == SERVER_PROGRESS) {
        # At the targeted protocol revision (54429) a Progress packet
        # is exactly these five varints. Later revisions append fields
        # (elapsed_ns, ...), but the Progress packet carries no
        # revision of its own, so the only safe stopping point without
        # threading the negotiated revision through is the end of the
        # 54429 layout. Reading a trailing field "if bytes remain"
        # would, on a buffer that already holds the next packet,
        # consume that packet's bytes instead.
        ($pkt{rows},          $offset) = unpack_varint($bytes, $offset);
        ($pkt{bytes},         $offset) = unpack_varint($bytes, $offset);
        ($pkt{total_rows},    $offset) = unpack_varint($bytes, $offset);
        ($pkt{written_rows},  $offset) = unpack_varint($bytes, $offset);
        ($pkt{written_bytes}, $offset) = unpack_varint($bytes, $offset);
    }
    elsif ($type == SERVER_PONG || $type == SERVER_END_OF_STREAM) {
        # No payload.
    }
    elsif ($type == SERVER_PROFILE_INFO) {
        ($pkt{rows},            $offset) = unpack_varint($bytes, $offset);
        ($pkt{blocks},          $offset) = unpack_varint($bytes, $offset);
        ($pkt{rows_bytes},      $offset) = unpack_varint($bytes, $offset);
        die "unpack_packet: truncated at offset $offset"
            if $offset >= length $bytes;
        $pkt{applied_limit} = ord substr($bytes, $offset++, 1);
        ($pkt{rows_before_limit}, $offset)
            = unpack_varint($bytes, $offset);
        die "unpack_packet: truncated at offset $offset"
            if $offset >= length $bytes;
        $pkt{calculated_rows_before_limit}
            = ord substr($bytes, $offset++, 1);
    }
    elsif ($type == SERVER_DATA || $type == SERVER_TOTALS || $type == SERVER_EXTREMES
        || $type == SERVER_LOG || $type == SERVER_PROFILE_EVENTS) {
        ($pkt{table_name}, $offset) = unpack_string($bytes, $offset) if $rev >= 50264;
        my $compressed = $opts{compressed} && $type != SERVER_LOG && $type != SERVER_PROFILE_EVENTS;
        if (!$compressed && $rev >= 51903) {
            ($pkt{block_info}, $offset) = unpack_block_info($bytes, $offset);
        }
        $pkt{block_offset} = $offset;
    }
    elsif ($type == SERVER_TABLE_COLUMNS) {
        ($pkt{table_name},       $offset) = unpack_string($bytes, $offset);
        ($pkt{column_descriptor}, $offset) = unpack_string($bytes, $offset);
    }
    else {
        die "unpack_packet: unknown server packet type $type\n";
    }
    return (\%pkt, $offset);
}

# Blocking read helper for IO::Socket / IO::Handle. Pulls bytes until
# one full packet parses, returns the packet hashref. For
# Data/Totals/Extremes/ProfileEvents packets the inner Native block
# bytes are read into $pkt->{block_bytes} (the raw slice ready for
# ClickHouse::Encoder->decode_block); $pkt->{block} carries the
# pre-decoded block hashref.
#
# Reads whatever sysread returns (up to 4 KiB at a time): the
# protocol packets are size-self-describing, so we let unpack_packet
# tell us when it has enough bytes. Avoids the trap of trying to
# block-read N bytes when the server has only sent K < N.
sub read_packet {
    my (undef, $fh, %opts) = @_;
    my $bufref = $opts{buffer} // \my $local_buf;
    $$bufref //= '';
    my $timeout = $opts{timeout};
    my ($deadline, $fd);
    if (defined $timeout) {
        require Time::HiRes;
        $deadline = Time::HiRes::time() + $timeout;
        $fd = fileno $fh;
    }
    my $read_some = sub {
        while (1) {
            if (defined $fd && $fd >= 0) {
                my $left = $deadline - Time::HiRes::time();
                my $expired = "read_packet: timed out after ${timeout}s waiting for the server\n";
                die $expired if $left <= 0;
                my $ready = '';
                vec($ready, $fd, 1) = 1;
                my $n = select($ready, undef, undef, $left);
                die $expired if $n == 0;
                if ($n < 0) {
                    next if $! == Errno::EINTR();
                    die "read_packet: select failed: $!\n";
                }
            }
            my $got = sysread $fh, my $chunk, 4096;
            next if !defined $got && $! == Errno::EINTR();
            die "read_packet: read error: $!\n" unless defined $got;
            die "read_packet: connection closed mid-packet\n" if !$got;
            $$bufref .= $chunk;
            return;
        }
    };
    my ($pkt, $end);
    while (1) {
        my $ok = eval { ($pkt, $end) = __PACKAGE__->unpack_packet($$bufref, 0, %opts); 1 };
        last if $ok;
        die $@ unless $@ =~ /truncated/;
        $read_some->();
    }
    if (exists $pkt->{block_offset}) {
        my $compressed = $opts{compressed}
            && $pkt->{type} != SERVER_LOG && $pkt->{type} != SERVER_PROFILE_EVENTS;
        if ($compressed) {
            my $plain = '';
            my $off = $pkt->{block_offset};
            while (1) {
                my ($frame, $consumed);
                while (1) {
                    my $ok = eval {
                        ($frame, $consumed) = ClickHouse::Encoder->decompress_native_block(
                            $$bufref, offset => $off); 1;
                    };
                    last if $ok;
                    die $@ unless $@ =~ /truncated header|extends past buffer/;
                    $read_some->();
                }
                $off += $consumed;
                $plain .= $frame;
                my $ok = eval {
                    my $start = 0;
                    if (($opts{revision} // DEFAULT_REVISION) >= 51903) {
                        ($pkt->{block_info}, $start) = unpack_block_info($plain, 0);
                    }
                    my $b = ClickHouse::Encoder->decode_block($plain, $start);
                    die "read_packet: trailing bytes in compressed Data packet\n"
                        unless $start + $b->{consumed} == length $plain;
                    $pkt->{block} = $b;
                    $pkt->{block_bytes} = substr($plain, $start);
                    $pkt->{compressed_consumed} = $off - $pkt->{block_offset};
                    1;
                };
                if ($ok) { $end = $off; last }
                die $@ unless $@ =~ /truncated|exceeds remaining buffer/;
            }
        } else {
            my $need_at = 0;
            while (1) {
                $read_some->() while length($$bufref) < $need_at;
                my $b = eval { ClickHouse::Encoder->decode_block($$bufref, $pkt->{block_offset}) };
                if (!$@) {
                    $pkt->{block} = $b;
                    $pkt->{block_bytes} = substr($$bufref, $pkt->{block_offset}, $b->{consumed});
                    $end = $pkt->{block_offset} + $b->{consumed};
                    last;
                }
                die $@ unless $@ =~ /truncated|exceeds remaining buffer/;
                $need_at = length($$bufref) + ($@ =~ /need (\d+) more/ ? $1 : 1);
            }
        }
    }
    substr($$bufref, 0, $end, '');
    return $pkt;
}

1;

__END__

=head1 NAME

ClickHouse::Encoder::TCP - Pack/unpack a useful subset of the ClickHouse native TCP protocol

=head1 SYNOPSIS

    use IO::Socket::INET;
    use ClickHouse::Encoder;
    use ClickHouse::Encoder::TCP;

    my $s = IO::Socket::INET->new(PeerAddr => 'db:9000') or die;
    binmode $s;

    # A caller-owned buffer threaded through every read_packet call -
    # required when reading more than one packet, since a single
    # sysread can pull in several packets at once.
    my $rbuf = '';

    # 1. Handshake
    print $s ClickHouse::Encoder::TCP->pack_hello(
        user => 'default', password => '', database => 'default');
    my $hello = ClickHouse::Encoder::TCP->read_packet($s, buffer => \$rbuf);
    die "expected Hello, got type $hello->{type}\n"
        unless $hello->{type} == ClickHouse::Encoder::TCP::SERVER_HELLO;

    # 2. insert query
    print $s ClickHouse::Encoder::TCP->pack_query(
        query => 'insert into events format native');

    # 3. Read TableColumns / empty Data packets the server sends back
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($s, buffer => \$rbuf);
        last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_DATA;
    }

    # 4. Send our data block(s)
    my $enc = ClickHouse::Encoder->new(columns => [
        ['ev', 'String'], ['ts', 'DateTime']]);
    my $block = $enc->encode([ ['login', time()] ]);
    print $s ClickHouse::Encoder::TCP->pack_data($block);

    # 5. End of insert
    print $s ClickHouse::Encoder::TCP->pack_data_end();

    # 6. Wait for EndOfStream / Exception
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($s, buffer => \$rbuf);
        last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_END_OF_STREAM;
        die "server exception: $p->{message}\n"
            if $p->{type} == ClickHouse::Encoder::TCP::SERVER_EXCEPTION;
    }
    close $s;

=head1 DESCRIPTION

A pure-Perl helper module that packs the few client packets needed
to drive an insert pipeline over the ClickHouse native TCP protocol
(port 9000), plus a decoder for the most common server packets:
C<Hello>, C<Data>, C<Exception>, C<Progress>, C<Pong>,
C<EndOfStream>, C<ProfileInfo>, C<TableColumns>, C<ProfileEvents>.

Targets protocol revision 54429 - newer fields are gated by the negotiated revision.

Transport (socket / TLS / framing) is the caller's responsibility.
L</read_packet> is provided as a convenience for blocking
C<IO::Socket>-style use; for non-blocking transports, call
L</unpack_packet> on a sliding byte buffer directly.

Out of scope:

=over 4

=item * Settings with typed values (newer flexible-setting wire form).

=item * select result streaming (covers what's needed for inserts).

=item * Server's prepared-query parameters protocol.

=back

Wire compression is supported as an opt-in: L</pack_data> /
L</pack_data_end> accept C<<< compress => 'lz4' >>> or C<'zstd'>,
and L</read_packet> accepts C<<< compressed => 1 >>>. See CAVEATS
for the negotiation handshake the caller must perform first.

For select, prefer HTTP - it's simpler and well-supported by
L<ClickHouse::Encoder>'s C<decode_block> / C<decode_stream>.

=head1 PACKET ENCODERS

=head2 pack_hello %opts

    my $bytes = ClickHouse::Encoder::TCP->pack_hello(
        client_name => 'my-app',  # default 'ClickHouse::Encoder'
        major       => 1,          # default 1
        minor       => 0,          # default 0
        revision    => 54429,      # default DEFAULT_REVISION
        database    => 'default',
        user        => 'default',
        password    => '',
    );

=head2 pack_query %opts

    my $bytes = ClickHouse::Encoder::TCP->pack_query(
        query    => 'insert into t format native',
        query_id => '',                       # let server generate
        settings => { max_memory_usage => '1000000000' },  # optional
        stage    => STAGE_COMPLETE,           # default
        compression => COMPRESSION_DISABLE,   # default
    );

C<settings> may be a hashref (legacy string-value form) or a raw
byte string already in the right shape.

Query packets include the empty Data terminator for external tables.

=head2 pack_data $block_bytes, %opts

    my $bytes = ClickHouse::Encoder::TCP->pack_data($block);
    my $bytes = ClickHouse::Encoder::TCP->pack_data($block,
        compress => 'lz4');   # or 'zstd'

Wraps an encoded Native block (from
L<ClickHouse::Encoder/encode>) in a Data packet with an optional
C<table_name> (usually empty for inserts).

With C<compress =E<gt> 'lz4'> (or C<'zstd'>, or C<'auto'> - any mode
L<ClickHouse::Encoder/compress_native_block> accepts) the block is
first wrapped in ClickHouse's compressed-block framing (16-byte
CityHash128 + 9-byte header + compressed payload) before being placed
inside the Data packet. The server must already be expecting
compressed data via the corresponding C<pack_query(... compression
=E<gt> COMPRESSION_ENABLE)>; sending compressed Data without
negotiating compression in the Query packet will be rejected as a
parse error by C<CompressedReadBuffer>. C<compress> absent, or
C<'none'> / C<'raw'>, emits the bare uncompressed block (the default).

=head2 pack_block_info / unpack_block_info

C<pack_block_info()> returns the default C<BlockInfo> bytes.
C<unpack_block_info($bytes, $offset)> returns C<($info, $new_offset)>.
TCP Data packets include this header before the Native block.

=head2 pack_data_end %opts

    my $bytes = ClickHouse::Encoder::TCP->pack_data_end();
    my $bytes = ClickHouse::Encoder::TCP->pack_data_end(
        compress => 'lz4');

Sends an empty Data packet; this is how an insert pipeline tells
the server "no more data". When compression was negotiated in the
Query, the empty block must be sent through the same compressed
framing so C<CompressedReadBuffer> parses it the same way -
C<compress> takes the same values as L</pack_data>.

=head2 pack_ping, pack_cancel

    my $b = ClickHouse::Encoder::TCP->pack_ping;

Trivial control packets.

=head1 PACKET DECODER

=head2 unpack_packet $bytes, $offset

    my ($pkt, $new_offset) = ClickHouse::Encoder::TCP->unpack_packet(
        $buffer, $offset);

Parse one server packet from C<$bytes> starting at C<$offset>.
Returns a hashref with at least C<type> (numeric, one of the
C<SERVER_*> constants) and packet-specific fields. Croaks on
truncated input - catch with C<eval> on a sliding-buffer reader.

For Data/Totals/Extremes/ProfileEvents packets the hashref carries
C<block_offset>: the byte offset where the inner Native block begins.
Pass C<<< substr($bytes, $block_offset) >>> to
C<<< ClickHouse::Encoder->decode_block >>> to extract rows.

=head2 read_packet $fh

    my $rbuf = '';
    my $pkt = ClickHouse::Encoder::TCP->read_packet($fh, buffer => \$rbuf);
    my $pkt = ClickHouse::Encoder::TCP->read_packet($fh, compressed => 1);
    my $pkt = ClickHouse::Encoder::TCP->read_packet($fh, timeout => 30);

Blocking read from a filehandle. C<sysread>s in chunks until it has
one whole packet, parses it, and returns the hashref. For Data-shaped
packets, also reads the inner block and surfaces C<block_bytes> +
pre-decoded C<block> hashref. Convenience only; non-blocking
transports should call L</unpack_packet> on their own buffer.

A single C<sysread> may pull in more than one packet. Pass
C<<< buffer =E<gt> \my $buf >>> and thread the same scalar ref
through every C<read_packet> call on the filehandle: read_packet
seeds itself from that buffer and leaves any over-read bytes there
for the next call. B<This is required to read more than one packet>
- without a caller buffer, over-read bytes are dropped and a second
C<read_packet> call may block or misparse. The compression and
buffer options are independent and may be combined.

C<<< timeout =E<gt> $seconds >>> bounds how long a single read may wait;
on expiry C<read_packet> croaks instead of blocking forever, which is
what a handshake against a too-new server does (see L</CAVEATS>).

When the caller has negotiated compression (via C<pack_query(...
compression =E<gt> COMPRESSION_ENABLE)>), pass C<compressed =E<gt>
1> so C<read_packet> peels the inner compressed-block framing
(16-byte CityHash128 + 9-byte header + LZ4/ZSTD payload) via
L<ClickHouse::Encoder/decompress_native_block> before decoding the
Native block. C<block_bytes> on the returned hashref is the
decompressed inner block; C<compressed_consumed> reports how many
on-the-wire bytes the framed block occupied.

=head1 WIRE CODECS

The varint and length-prefixed-string codecs the packet builders use
are XS-backed and callable directly. They are a semi-public surface:
stable and reusable, but secondary to the packet-level API above.
They are plain functions (not class methods) - invoke them fully
qualified, e.g. C<ClickHouse::Encoder::TCP::pack_varint($n)>.

=over 4

=item pack_varint $uint

Encode a non-negative integer in ClickHouse's LEB128 varuint form;
returns the byte string.

=item unpack_varint $bytes, $offset

Decode one varint at C<$offset>; returns C<($value, $new_offset)>.
Croaks on truncated input or a varint wider than 64 bits.

=item pack_string $str

Encode a length-prefixed string: a varint length followed by the
UTF-8 bytes of C<$str>. Returns the byte string.

=item unpack_string $bytes, $offset

Decode one length-prefixed string at C<$offset>; returns
C<($string, $new_offset)> with the raw (undecoded) string bytes.

=back

=head1 CONSTANTS

Client packet types: C<CLIENT_HELLO>, C<CLIENT_QUERY>, C<CLIENT_DATA>,
C<CLIENT_CANCEL>, C<CLIENT_PING>.

Server packet types: C<SERVER_HELLO>, C<SERVER_DATA>,
C<SERVER_EXCEPTION>, C<SERVER_PROGRESS>, C<SERVER_PONG>,
C<SERVER_END_OF_STREAM>, C<SERVER_PROFILE_INFO>, C<SERVER_TOTALS>,
C<SERVER_EXTREMES>, C<SERVER_TABLE_COLUMNS>, C<SERVER_PROFILE_EVENTS>.

Other: C<STAGE_COMPLETE>, C<STAGE_WITH_MERGEABLE>,
C<STAGE_FETCH_COLUMNS>, C<COMPRESSION_DISABLE>, C<COMPRESSION_ENABLE>,
C<DEFAULT_REVISION>.

All constants live in the package namespace and are not exported;
reference them as C<ClickHouse::Encoder::TCP::SERVER_DATA> etc.

=head1 CAVEATS

=over 4

=item * B<Protocol revision.> Use the default revision 54429 with modern
servers. Raising it requires additional handshake and packet fields.

=item * B<String encoding.> C<pack_string> uses UTF-8 for character
strings and preserves byte strings. C<unpack_string> returns bytes.

=item * B<Settings values are strings.> Each setting is emitted with
flags=0 (ordinary) and the value as a string. Numeric/typed-setting
encoding (flexible settings, available at higher revisions) is out
of scope.

=item * B<Wire compression is opt-in.> C<pack_query> still defaults
to C<COMPRESSION_DISABLE>; to negotiate compression pass
C<compression =E<gt> COMPRESSION_ENABLE> in C<pack_query>, then
C<compress =E<gt> 'lz4'> (or C<'zstd'>) to both C<pack_data> and
C<pack_data_end>. Compressed Data packets coming back from the
server are decoded by C<read_packet($fh, compressed =E<gt> 1)>.
The compressed-block framing (16-byte CityHash128 v1.0.2 + 9-byte
header + payload) lives in L<ClickHouse::Encoder/compress_native_block>.

=back

=head1 SEE ALSO

L<ClickHouse::Encoder> - the wire-format encoder these packets carry,
plus L<compress_native_block|ClickHouse::Encoder/compress_native_block>
/ L<decompress_native_block|ClickHouse::Encoder/decompress_native_block>
for the matching block-framing helpers.

L<EV::ClickHouse> - full async ClickHouse client (TCP + HTTP) for
select result streaming, prepared queries with parameter binding,
and chunking-negotiation against modern CH revisions.

=head1 AUTHOR

vividsnow

=head1 LICENSE

Same terms as Perl itself.

=cut
