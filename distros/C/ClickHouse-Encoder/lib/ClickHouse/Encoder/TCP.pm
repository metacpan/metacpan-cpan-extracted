package ClickHouse::Encoder::TCP;  ## no critic (Capitalization)
use strict;
use warnings;

our $VERSION = '0.01';

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
# Targets protocol revision 54429: predates flexible settings,
# inter-server secret, OpenTelemetry, parallel-replica fields, and
# the recent chunking negotiation extension. Modern CH servers
# (protocol revision >= ~54475) handshake additional bytes past
# Hello that this subset doesn't respond to - prefer HTTP for
# integration with recent servers.

# XS loader handled by the parent module; ensure it's loaded so the
# XSUBs under PACKAGE = ClickHouse::Encoder::TCP are available.
use ClickHouse::Encoder ();

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
#   string  settings  (\n-separated key=value pairs, empty for none)
#   varint  query_processing_stage (default Complete)
#   varint  compression flag (default Disable)
#   string  query SQL text
sub pack_query {
    my (undef, %o) = @_;
    return pack_varint(CLIENT_QUERY)
         . pack_string($o{query_id} // '')
         . _pack_client_info(\%o)
         . _pack_settings($o{settings})
         . pack_varint($o{stage}       // STAGE_COMPLETE)
         . pack_varint($o{compression} // COMPRESSION_DISABLE)
         . pack_string($o{query} // die "pack_query: 'query' is required\n");
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
    $out .= chr($o->{query_kind} // 1);   # 1 = initial query
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
sub pack_data {
    my (undef, $block_bytes, %o) = @_;
    die "pack_data: block bytes required\n" unless defined $block_bytes;
    if (defined $o{compress} && $o{compress} ne 'none' && $o{compress} ne 'raw') {
        $block_bytes = ClickHouse::Encoder->compress_native_block(
            $block_bytes, mode => $o{compress});
    }
    return pack_varint(CLIENT_DATA)
         . pack_string($o{table_name} // '')
         . $block_bytes;
}

# Empty data packet: signals end of insert. Even with negotiated
# compression, the end-of-insert empty block goes through the same
# compressed-block framing so the server's CompressedReadBuffer parses
# it the same way every other Data packet.
sub pack_data_end {
    my (undef, %o) = @_;
    # A "data" packet with an empty Native block: ncols=0, nrows=0.
    my $empty_block = pack_varint(0) . pack_varint(0);  # ncols + nrows
    if (defined $o{compress} && $o{compress} ne 'none' && $o{compress} ne 'raw') {
        $empty_block = ClickHouse::Encoder->compress_native_block(
            $empty_block, mode => $o{compress});
    }
    return pack_varint(CLIENT_DATA)
         . pack_string($o{table_name} // '')
         . $empty_block;
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
    my (undef, $bytes, $offset) = @_;
    $offset //= 0;
    (my $type, $offset) = unpack_varint($bytes, $offset);
    my %pkt = (type => $type);
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
        if ($pkt{revision} >= 54058) {
            ($pkt{timezone}, $offset)
                = unpack_string($bytes, $offset);
        }
        if ($pkt{revision} >= 54372) {
            ($pkt{display_name}, $offset)
                = unpack_string($bytes, $offset);
        }
        if ($pkt{revision} >= 54401) {
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
    elsif ($type == SERVER_DATA || $type == SERVER_TOTALS
        || $type == SERVER_EXTREMES) {
        # Data packet: table_name then a Native block payload.
        # We surface the table name and the byte range of the block;
        # the caller passes those bytes to ClickHouse::Encoder->decode_block.
        ($pkt{table_name}, $offset) = unpack_string($bytes, $offset);
        $pkt{block_offset} = $offset;
        # Caller decodes from here; advancing $offset requires parsing
        # the inner block (ncols + nrows + per-column bytes). For the
        # caller's convenience we don't attempt that here - they should
        # use ClickHouse::Encoder->decode_block on the slice and add
        # block_consumed = $decoded->{consumed} to advance.
    }
    elsif ($type == SERVER_TABLE_COLUMNS) {
        ($pkt{table_name},       $offset) = unpack_string($bytes, $offset);
        ($pkt{column_descriptor}, $offset) = unpack_string($bytes, $offset);
    }
    elsif ($type == SERVER_PROFILE_EVENTS) {
        # Same shape as a Data packet.
        ($pkt{table_name}, $offset) = unpack_string($bytes, $offset);
        $pkt{block_offset} = $offset;
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
    # When `compressed => 1` is passed, the inner Native block of any
    # Data-shaped packet is expected to be wrapped in CH's
    # compressed-block framing (16-byte CityHash128 + 9-byte header +
    # LZ4/ZSTD/raw payload). This must match what the caller negotiated
    # in pack_query(... compression => COMPRESSION_ENABLE); reading
    # without `compressed => 1` from a connection that DOES use
    # compression will misparse the Native block and croak with a
    # decode error rather than a clean diagnostic.
    my $compressed = $opts{compressed};
    # Optional caller-owned buffer: pass `buffer => \my $buf` and thread
    # the same ref through every read_packet call on this filehandle.
    # A fast server can pack several packets into one TCP segment;
    # read_packet then leaves the bytes it over-read in that buffer for
    # the next call. Without it, read_packet is a one-shot helper and
    # over-read bytes are lost - unsafe to call in a loop.
    my $bufref = $opts{buffer};
    my $buf = $bufref ? $$bufref : '';
    my $read_some = sub {
        my $got = sysread $fh, my $chunk, 4096;
        die "read_packet: read error: $!\n" if !defined $got;
        die "read_packet: connection closed mid-packet\n" if $got == 0;
        $buf .= $chunk;
    };

    my $pkt;
    my $end;   # offset just past the consumed packet
    while (1) {
        my $ok = eval {
            ($pkt, $end) = __PACKAGE__->unpack_packet($buf, 0);
            1;
        };
        last if $ok;
        die $@ unless $@ =~ /truncated/;
        $read_some->();
    }

    # For Data-shaped packets, also pull the inner Native block bytes.
    # decode_block tells us how many bytes it consumed; if the block
    # is still truncated, read more and retry.
    if (exists $pkt->{block_offset}) {
        require ClickHouse::Encoder;
        if ($compressed) {
            # Step 1: pull the compressed-block frame (16 hash + 9 hdr
            # + payload). Read more bytes until the frame is complete.
            while (1) {
                my $ok = eval {
                    my ($plain, $consumed) =
                        ClickHouse::Encoder->decompress_native_block(
                            $buf, offset => $pkt->{block_offset});
                    # Decode the inner Native block out of $plain.
                    my $b = ClickHouse::Encoder->decode_block($plain);
                    $pkt->{block}       = $b;
                    $pkt->{block_bytes} = $plain;   # decompressed bytes
                    $pkt->{compressed_consumed} = $consumed;
                    1;
                };
                last if $ok;
                # decompress_native_block raises "truncated header" /
                # "block extends past buffer end" when more bytes are
                # needed; also "buffer truncated" on the inner Native
                # parse (shouldn't fire after decompress succeeds).
                die $@ unless $@ =~ /truncated|extends past|need \d+ more/;
                $read_some->();
            }
            $end = $pkt->{block_offset} + $pkt->{compressed_consumed};
        } else {
            while (1) {
                my $ok = eval {
                    my $b = ClickHouse::Encoder->decode_block(
                        substr($buf, $pkt->{block_offset}));
                    $pkt->{block}       = $b;
                    $pkt->{block_bytes} =
                        substr($buf, $pkt->{block_offset}, $b->{consumed});
                    1;
                };
                last if $ok;
                die $@ unless $@ =~ /truncated/;
                $read_some->();
            }
            $end = $pkt->{block_offset} + length $pkt->{block_bytes};
        }
    }
    # Hand any over-read bytes back to the caller's buffer so a looping
    # caller does not lose packets the same sysread happened to pull in.
    # Without a caller buffer those bytes are dropped (one-shot mode).
    $$bufref = substr($buf, $end) if $bufref;
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

Targets protocol revision 54429 - the same revision ClickHouse
clients have used since ~2020. Newer fields the server may include
(timezone, display_name, version_patch) are read opportunistically
when present.

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

=item * B<Modern server cutoff.> The default revision (54429) predates
the chunking-negotiation extension introduced in ClickHouse 24.10
(protocol revision E<gt>= 54475). Newer servers send a chunking offer
right after C<SERVER_HELLO> that this subset does not respond to;
the connection then fails with a fast protocol-mismatch error.
For integration with recent servers, prefer HTTP transport.

=item * B<String encoding.> Inputs to C<pack_string> (any string
field: query, names, settings) are encoded as UTF-8 bytes; passing a
byte-mode string with non-ASCII bytes will be reinterpreted as
Latin-1 by Perl's UTF-8 upgrade rules. If you need raw bytes, encode
to UTF-8 yourself first. C<unpack_string> conversely returns the
raw byte string the server sent - it does not set the UTF-8 flag,
so callers wanting characters should C<decode_utf8> the result.

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
