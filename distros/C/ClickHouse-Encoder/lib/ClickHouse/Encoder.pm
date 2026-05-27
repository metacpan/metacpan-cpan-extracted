package ClickHouse::Encoder;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('ClickHouse::Encoder', $VERSION);

# Validate a [db.]table identifier as ASCII word characters only.
# Rejects anything that could inject SQL via the --query argument.
sub _validate_table_name {
    my $table = shift;
    $table =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?\z/
        or die "Invalid table name '$table': expected [db.]name with [A-Za-z0-9_]";
    return;
}

# Build (url, headers) for a ClickHouse HTTP request with the given SQL
# in the `query` parameter. Pulls connection params from %opts using
# the same defaults as for_table / insert_http. UTF-8 encodes before
# percent-escaping so non-ASCII (caf%C3%A9, emoji) round-trips correctly.
sub _http_url_headers {
    my ($sql, %opts) = @_;
    require Encode;
    my $esc = sub {
        my $s = Encode::encode('UTF-8', $_[0], 0);
        $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
        $s;
    };
    my ($scheme, $host, $port) = _check_endpoint(\%opts);
    my $database = $opts{database} // 'default';
    my $user     = $opts{user}     // 'default';
    my $password = $opts{password} // '';
    my $url = "$scheme://$host:$port/?database=" . $esc->($database);
    $url .= "&query=" . $esc->($sql) if length $sql;
    # Per-query settings: { max_memory_usage => '...', max_execution_time => 30 }
    if (my $s = $opts{settings}) {
        for my $k (sort keys %$s) {
            $url .= "&" . $esc->($k) . "=" . $esc->($s->{$k});
        }
    }
    # Insert-side idempotency token: identical token + payload is rejected.
    if (defined(my $tok = $opts{dedup_token})) {
        $url .= "&insert_deduplication_token=" . $esc->($tok);
    }
    my %hdr = ('X-ClickHouse-User' => $user);
    $hdr{'X-ClickHouse-Key'} = $password if $password ne '';
    return ($url, \%hdr);
}

# Validate the host/port/scheme triple shared by every HTTP entry point.
# Rejects anything other than http/https, ensures the port is a positive
# integer, and refuses host strings that contain URL-structural characters
# (':/?#&'). Centralised here so insert_http, bulk_inserter, ping, and
# select_blocks share a single allow-list and identical error messages.
sub _check_endpoint {
    my ($opts) = @_;
    my $scheme = $opts->{scheme} // 'http';
    my $host   = $opts->{host}   // 'localhost';
    my $port   = $opts->{port}   // 8123;
    die "endpoint: scheme must be 'http' or 'https' (got '$scheme')\n"
        unless $scheme eq 'http' || $scheme eq 'https';
    die "endpoint: host must not contain URL-structural characters "
      . "(got '$host')\n"
        if $host =~ m{[:/?#&\s]} || !length $host;
    die "endpoint: port must be a positive integer (got '$port')\n"
        unless $port =~ /\A[1-9]\d{0,4}\z/ && $port < 65536;
    return ($scheme, $host, $port);
}

# Build an HTTP::Tiny instance honoring ssl_options (verify_SSL, SSL_ca_file,
# etc.) and keep_alive. Shared by insert_http, bulk_inserter, server_version,
# ping, select_blocks; callers pass %opts unchanged. Loading HTTP::Tiny here
# keeps the require local to HTTP code paths.
sub _http_tiny {
    my (%opts) = @_;
    require HTTP::Tiny;
    my @args = (timeout => $opts{timeout} // 60);
    push @args, keep_alive => 1 if $opts{keep_alive};
    push @args, SSL_options => $opts{ssl_options} if $opts{ssl_options};
    push @args, verify_SSL  => $opts{verify_SSL}  if exists $opts{verify_SSL};
    return HTTP::Tiny->new(@args);
}

# Parse a flat CH JSON object string (X-ClickHouse-Summary /
# X-ClickHouse-Progress) without depending on JSON::PP. Both are small
# flat objects of stringified integers (read_rows, written_rows,
# total_rows_to_read, elapsed_ns, ...). Returns a hashref or undef.
sub _parse_ch_kv {
    my ($str) = @_;
    return unless defined $str && length $str;
    my %h;
    # NB: stash $1/$2 before the digit-test regex - that regex resets
    # capture variables and would silently turn every key into ''.
    while ($str =~ /"([^"\\]+)"\s*:\s*"([^"\\]*)"/g) {
        my ($k, $v) = ($1, $2);
        $h{$k} = ($v =~ /\A-?\d+\z/) ? $v + 0 : $v;
    }
    return scalar(keys %h) ? \%h : undef;
}

# Lift a few ClickHouse response headers into a small hashref. Returns
# undef when none are present; otherwise carries query_id, server
# (revision), format, a parsed summary, and the final progress snapshot
# so callers don't reparse the same headers. X-ClickHouse-Progress is
# sent repeatedly while a query runs (with send_progress_in_http_headers
# =1); HTTP::Tiny collapses repeats into an arrayref, so we take the
# last - the most complete - snapshot.
sub _decorate_response {
    my ($resp) = @_;
    return $resp unless ref $resp eq 'HASH';
    my $h = $resp->{headers} or return $resp;
    my %ch;
    for my $k (qw(query-id server format exception-code)) {
        my $hv = $h->{"x-clickhouse-$k"};
        $ch{$k} = $hv if defined $hv;
    }
    if (my $sum = _parse_ch_kv($h->{'x-clickhouse-summary'})) {
        $ch{summary} = $sum;
    }
    if (defined(my $pv = $h->{'x-clickhouse-progress'})) {
        $pv = $pv->[-1] if ref $pv eq 'ARRAY';
        if (my $prog = _parse_ch_kv($pv)) {
            $ch{progress} = $prog;
        }
    }
    $resp->{ch} = \%ch if %ch;
    return $resp;
}

sub for_table {
    my ($class, $table, %opts) = @_;
    _validate_table_name($table);
    return $class->_for_describe("describe table $table", %opts);
}

sub _for_describe {
    my ($class, $describe_sql, %opts) = @_;

    my $via = $opts{via} // 'client';
    my @lines;

    if ($via eq 'http') {
        my ($url, $hdr) = _http_url_headers(
            "$describe_sql format tabseparated", %opts);
        my $resp = _http_tiny(%opts, timeout => $opts{timeout} // 10)
            ->get($url, { headers => $hdr });
        die "HTTP describe table failed (status $resp->{status}): $resp->{content}\n"
            unless $resp->{success};
        @lines = split /\n/, $resp->{content};
    }
    elsif ($via eq 'client') {
        my $host     = $opts{host}     // 'localhost';
        my $port     = $opts{port}     // 9000;
        my $database = $opts{database} // 'default';
        my $user     = $opts{user}     // 'default';
        my $password = $opts{password} // '';
        my $client   = $opts{client}   // 'clickhouse-client';

        my @cmd = (
            $client,
            '--host', $host,
            '--port', $port,
            '--database', $database,
            '--user', $user,
            '--query', "$describe_sql format tabseparated",
        );

        # Pass password via env so it doesn't show up in `ps`. Always
        # set $password (even empty) so an empty `password => ''` arg
        # also overrides any inherited CLICKHOUSE_PASSWORD.
        local $ENV{CLICKHOUSE_PASSWORD} = $password;

        open my $fh, '-|', @cmd
            or die "Failed to run clickhouse-client: $!";
        @lines = <$fh>;
        close $fh;
        die "clickhouse-client failed: exit code " . ($? >> 8) if $?;
    }
    else {
        die "Unknown via='$via' (expected 'client' or 'http')";
    }

    my @columns;
    # ClickHouse's TabSeparated format escapes \\ \n \t \r \0 in field
    # values. Multi-line type expressions (e.g. named Tuple, Nested) come
    # out as a single TSV line with embedded \n and indentation; un-escape
    # so the XS parser sees the canonical type string. The default branch
    # ($1) handles \\ -> \ and any other backslash-escape forms transparently.
    my $unesc = sub {
        my $s = shift // '';
        $s =~ s{\\(.)}{ $1 eq 'n' ? "\n"
                      : $1 eq 't' ? "\t"
                      : $1 eq 'r' ? "\r"
                      : $1 eq '0' ? "\0"
                      : $1 }ge;
        $s;
    };
    for my $line (@lines) {
        chomp $line;
        next if $line eq '';
        my ($name, $type) = split /\t/, $line;
        push @columns, [$unesc->($name), $unesc->($type)];
    }

    die "No columns found for: $describe_sql" unless @columns;
    return $class->new(columns => \@columns);
}

sub columns {
    my $self = shift;
    return $self->_columns;
}

sub validate_rows {
    my ($self, $rows) = @_;
    my @errors;
    for my $i (0 .. $#$rows) {
        local $@;
        unless (eval { $self->encode([$rows->[$i]]); 1 }) {
            (my $msg = "$@") =~ s/\s*at .+ line \d+\.\s*\z//;
            push @errors, { row => $i, error => $msg };
        }
    }
    return \@errors;
}

sub compressed_writer {
    my ($class, $mode, $writer) = @_;
    return $writer if !defined $mode || $mode eq 'raw';
    if ($mode eq 'zstd') {
        require Compress::Zstd;
        return sub {
            my $out = Compress::Zstd::compress($_[0]);
            defined $out or die "zstd compression failed";
            $writer->($out);
        };
    }
    if ($mode eq 'gzip') {
        require IO::Compress::Gzip;
        return sub {
            my $out;
            IO::Compress::Gzip::gzip(\$_[0], \$out)
                or die "gzip failed: $IO::Compress::Gzip::GzipError";
            $writer->($out);
        };
    }
    die "Unknown compress mode '$mode' (expected 'zstd', 'gzip', or 'raw')";
}

# Compressed-block framing used by ClickHouse's CompressedReadBuffer /
# CompressedWriteBuffer (native TCP protocol with compression=1 enabled,
# and Native-over-HTTP with Content-Encoding: clickhouse-lz4 etc).
# Layout:
#     16 bytes : checksum (CityHash128 of the next 9 + N bytes)
#      1 byte  : method tag (0x82 LZ4, 0x90 ZSTD, 0x02 none)
#      4 bytes : compressed_size = 1 + 4 + 4 + N  (LE UInt32)
#      4 bytes : uncompressed_size                (LE UInt32)
#      N bytes : compressed payload
#
# CH's checksum is CityHash128 from the "cityhash102" variant (Google
# CityHash v1.0.2 with ClickHouse's namespace fork). We bundle a port
# of that algorithm in cityhash.c, exposed as the `_cityhash128` XSUB,
# used as the default hasher below. Callers can plug in a different
# 16-byte hasher via the `hasher => \&h` option.
my %_COMPRESS_METHOD_TAG = (lz4 => 0x82, zstd => 0x90, none => 0x02);

sub compress_native_block {
    my ($class, $bytes, %opts) = @_;
    my $mode   = $opts{mode}   // 'lz4';
    # Default to the bundled CityHash128 v1.0.2 (the "cityhash102"
    # variant CH itself uses for the compressed-block checksum). The
    # `hasher` opt is still honored for callers that want to plug in
    # something else (Digest::CityHash, a vendored copy, etc.).
    my $hasher = $opts{hasher} // \&_cityhash128;

    # mode=auto: try LZ4 first, fall back to method-tag 0x02 (uncompressed
    # inside compressed framing - same shape CH's own CompressedWriteBuffer
    # emits when the compressed result is >= the input). Saves CPU on
    # already-incompressible payloads without giving up the checksum
    # protection of the framing.
    # The auto-mode probe doubles as the payload when LZ4 wins, so the
    # input is compressed at most once regardless of which branch wins.
    my $payload;
    if ($mode eq 'auto') {
        require Compress::LZ4;
        my $lz4 = Compress::LZ4::lz4_compress($bytes);
        if (length($lz4) < length($bytes)) {
            $mode    = 'lz4';
            $payload = $lz4;
        } else {
            $mode = 'none';
        }
    }

    my $tag = $_COMPRESS_METHOD_TAG{$mode}
        or die "compress_native_block: unknown mode '$mode' "
             . "(expected 'auto', 'lz4', 'zstd', or 'none')\n";

    if (!defined $payload) {
        if ($mode eq 'lz4') {
            require Compress::LZ4;
            # Compress::LZ4::compress() prepends a 4-byte size header
            # that ClickHouse doesn't want; lz4_compress is the raw-
            # form variant emitting just the LZ4 byte stream.
            $payload = Compress::LZ4::lz4_compress($bytes);
        } elsif ($mode eq 'zstd') {
            require Compress::Zstd;
            my $z = Compress::Zstd::compress($bytes);
            defined $z
                or die "compress_native_block: zstd compression failed\n";
            $payload = $z;
        } else {  # none = uncompressed inside framing (method tag 0x02)
            $payload = $bytes;
        }
    }

    my $compressed_size = 1 + 4 + 4 + length($payload);  # tag + 2*UInt32 + N
    my $hdr = pack('C V V', $tag, $compressed_size, length $bytes);
    my $checksum = $hasher->($hdr . $payload);
    die "compress_native_block: hasher returned "
      . length($checksum) . " bytes (expected 16)\n"
        unless length($checksum) == 16;
    return $checksum . $hdr . $payload;
}

# Inverse of compress_native_block. Returns (uncompressed_bytes, bytes_consumed).
# Verifies the checksum if a hasher is supplied; if hasher is omitted the
# block is decompressed without verification (useful for inspecting captured
# data when the cityhash impl isn't available).
sub decompress_native_block {
    my ($class, $bytes, %opts) = @_;
    my $off = $opts{offset} // 0;
    # Same default as compress_native_block. Callers can pass
    # hasher => undef explicitly to skip checksum verification.
    my $hasher = exists $opts{hasher} ? $opts{hasher} : \&_cityhash128;
    my $total  = length $bytes;
    die "decompress_native_block: truncated header at offset $off "
      . "(need >= 25 bytes, have " . ($total - $off) . ")\n"
        if $total - $off < 25;

    my $checksum = substr($bytes, $off,      16);
    my $tag      = ord substr($bytes, $off + 16, 1);
    my $csize    = unpack 'V', substr($bytes, $off + 17, 4);  # incl. 9-byte header
    my $usize    = unpack 'V', substr($bytes, $off + 21, 4);

    die "decompress_native_block: compressed_size=$csize < 9 (corrupt)\n"
        if $csize < 9;
    my $payload_len = $csize - 9;
    my $end = $off + 16 + $csize;
    die "decompress_native_block: block extends past buffer end\n"
        if $end > $total;

    my $hdr     = substr($bytes, $off + 16, 9);
    my $payload = substr($bytes, $off + 25, $payload_len);

    if ($hasher) {
        my $got = $hasher->($hdr . $payload);
        die "decompress_native_block: checksum mismatch\n"
            unless $got eq $checksum;
    }

    my $out;
    if ($tag == 0x02) {  # uncompressed inside framing
        $out = $payload;
    } elsif ($tag == 0x82) {  # LZ4
        require Compress::LZ4;
        # lz4_decompress wants the expected uncompressed size as its
        # second argument since the raw stream has no length prefix.
        $out = Compress::LZ4::lz4_decompress($payload, $usize);
        die "decompress_native_block: lz4 decompression failed\n"
            unless defined $out;
    } elsif ($tag == 0x90) {  # ZSTD
        require Compress::Zstd;
        $out = Compress::Zstd::decompress($payload);
        die "decompress_native_block: zstd decompression failed\n"
            unless defined $out;
    } else {
        die sprintf("decompress_native_block: unknown method tag 0x%02x "
                  . "(expected 0x02 NONE, 0x82 LZ4, or 0x90 ZSTD)\n", $tag);
    }
    die "decompress_native_block: decompressed size mismatch "
      . "(header says $usize, got " . length($out) . ")\n"
        unless length($out) == $usize;
    return wantarray ? ($out, $end - $off) : $out;
}

# Expand any Nested(field T, ...) entries in a column list into the flat
# `name.field Array(T)` columns ClickHouse stores them as. Returns a new
# arrayref; non-Nested columns pass through unchanged. Pair with new():
#     my $enc = ClickHouse::Encoder->new(
#         columns => ClickHouse::Encoder->flatten_nested(\@user_columns));
sub flatten_nested {
    my ($class, $cols) = @_;
    my @out;
    for my $c (@$cols) {
        my ($name, $type) = @$c;
        if ($type =~ /\ANested\((.+)\)\z/s) {
            my @parts = _split_paren_list($1);
            @parts or die "Nested($1) for column '$name' has no elements";
            for my $part (@parts) {
                $part =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s+(.+?)\s*\z/s
                    or die "Nested element '$part' is not 'name Type'";
                push @out, ["$name.$1", "Array($2)"];
            }
        } else {
            push @out, [$name, $type];
        }
    }
    return \@out;
}

# Split a comma-separated list at depth-0 commas (so Tuple(Int32, String)
# inside a Nested element stays one entry).
sub _split_paren_list {
    my $body = shift;
    my @parts;
    my ($start, $depth, $len) = (0, 0, length $body);
    for (my $i = 0; $i <= $len; $i++) {
        my $c = $i < $len ? substr($body, $i, 1) : ',';
        if    ($c eq '(') { $depth++ }
        elsif ($c eq ')') { $depth-- }
        elsif ($c eq ',' && $depth == 0) {
            (my $p = substr($body, $start, $i - $start)) =~ s/\A\s+|\s+\z//g;
            push @parts, $p if length $p;
            $start = $i + 1;
        }
    }
    return @parts;
}

# Row-oriented decode: { ncols, nrows, names, types, rows } where
# rows is an arrayref of arrayrefs. Calls the XS decode_block_rows,
# which distributes column values into per-row arrayrefs as each
# column is decoded and frees the column AV eagerly. Peak memory
# is one column's AV plus the row AVs (vs a Perl-side transpose
# that holds ALL column AVs alongside the half-built row AVs).
# Throughput is similar to the column-major path; the win is the
# tighter memory profile on wide blocks.
sub decode_rows {
    my ($class, $bytes, $offset) = @_;
    return $class->decode_block_rows($bytes, $offset // 0);
}

# Decode a concatenated stream of Native blocks (the body of a
# `select ... format native` response). Returns an arrayref of the
# same hashref shape as decode_block. Stops cleanly when bytes are
# exhausted; partial trailing bytes raise an error from XS.
# Uses the 3-arg form of decode_block (with offset) to avoid O(N^2)
# substr copies on long streams.
sub decode_blocks {
    my ($class, $bytes, $cb, %opts) = @_;
    my $keep = $opts{keep};
    my $off = 0;
    my $len = length $bytes;
    # Callback form: hand each block to $cb as it's decoded; never
    # accumulate. Useful for streaming selects where the full block
    # list would not fit comfortably in memory.
    if ($cb) {
        while ($off < $len) {
            my $block = $class->decode_block($bytes, $off, $keep);
            $off += $block->{consumed};
            $cb->($block);
        }
        return;
    }
    my @blocks;
    while ($off < $len) {
        my $block = $class->decode_block($bytes, $off, $keep);
        $off += $block->{consumed};
        push @blocks, $block;
    }
    return \@blocks;
}

# Return a coderef that yields one block per call (undef when done).
# Holds a reference to $bytes; the closure is the only thing that
# survives between calls.
sub decode_blocks_iter {
    my ($class, $bytes, %opts) = @_;
    my $keep = $opts{keep};
    my $off = 0;
    my $len = length $bytes;
    return sub {
        return if $off >= $len;
        my $block = $class->decode_block($bytes, $off, $keep);
        $off += $block->{consumed};
        return $block;
    };
}

# Pull-style decoder that reads incrementally from a filehandle (or
# any IO::Handle-ish object). For each complete block, invokes $cb
# with the block hashref. Keeps a sliding buffer; on truncated decode
# it reads more bytes and retries. Useful when the response body is
# too large to fit in memory.
sub decode_stream {
    my ($class, $fh, $cb, %opts) = @_;
    my $chunk_size = $opts{chunk_size} // 64 * 1024;
    my $keep       = $opts{keep};
    my $decompress = $opts{decompress};
    my $buf = '';        # raw bytes from the filehandle
    my $inner = '';      # decompressed Native bytes (== $buf when !decompress)
    my $done = 0;
    until ($done) {
        # Phase 1: peel compressed-block frames out of $buf into $inner.
        if ($decompress) {
            while (length($buf) >= 25) {
                my $csize = unpack 'V', substr($buf, 17, 4);
                last if length($buf) < 16 + $csize;
                my ($plain, $consumed) = eval {
                    $class->decompress_native_block($buf)
                };
                die $@ if $@;
                $inner .= $plain;
                substr($buf, 0, $consumed, '');
            }
        } else {
            $inner = $buf;
        }
        # Phase 2: decode complete Native blocks out of $inner.
        while (length($inner) > 0) {
            my $block = eval { $class->decode_block($inner, 0, $keep) };
            if ($@) {
                # Truncation or malformed mid-block; need more bytes.
                # Only "buffer truncated" means "data ran short, read
                # more"; "exceeds remaining" indicates a malformed wire
                # value (e.g. a corrupted varint count) and should die
                # rather than spin reading more bytes.
                last if $@ =~ /buffer truncated/i;
                die $@;  # real error
            }
            $cb->($block);
            substr($inner, 0, $block->{consumed}, '');
        }
        # When not decompressing, $inner aliases $buf - carry the residual
        # back so the next read sees the unconsumed tail.
        $buf = $inner unless $decompress;
        # Read more bytes. read() returns 0 on EOF, undef on error.
        my $more;
        my $n = read $fh, $more, $chunk_size;
        die "decode_stream: read error: $!" if !defined $n;
        if ($n == 0) {
            # EOF. If anything is left in either buffer it's a truncated
            # final block; raise rather than swallow.
            die "decode_stream: " . length($buf) . " trailing bytes "
              . "after last complete compressed block"
                if $decompress && length $buf;
            die "decode_stream: " . length($inner) . " trailing bytes "
              . "after last complete block" if length $inner;
            $done = 1;
        } else {
            $buf .= $more;
        }
    }
    return;
}

# Query the ClickHouse HTTP endpoint for its version. Returns a list
# of (major, minor, patch, build) integers and the raw string. Useful
# for capability gating in user code (e.g. only use JSON columns if
# the server is at least 24.8). HTTP-only; native TCP not supported.
sub server_version {
    my ($class, %opts) = @_;
    my ($url, $hdr) = _http_url_headers('select version()', %opts);
    my $resp = _http_tiny(%opts, timeout => $opts{timeout} // 10)
        ->get($url, { headers => $hdr });
    die "HTTP select version() failed (status $resp->{status}): "
      . "$resp->{content}\n"
        unless $resp->{success};
    (my $raw = $resp->{content}) =~ s/\s+\z//;
    my @parts = ($raw =~ /(\d+)/g);
    return wantarray
        ? (@parts, $raw)
        : { major => $parts[0] // 0, minor => $parts[1] // 0,
            patch => $parts[2] // 0, build => $parts[3] // 0,
            raw   => $raw };
}

# Lightweight liveness check via CH's /ping endpoint. Returns 1 on
# success; croaks on HTTP failure (which includes connection refused,
# timeout, or non-2xx response). Use to gate on server availability in
# bootstrap scripts and bulk-load orchestration.
sub ping {
    my ($class, %opts) = @_;
    my ($scheme, $host, $port) = _check_endpoint(\%opts);
    my $url    = "$scheme://$host:$port/ping";
    my $resp   = _http_tiny(%opts, timeout => $opts{timeout} // 5)->get($url);
    die "ping: HTTP $resp->{status}: $resp->{content}\n"
        unless $resp->{success};
    return 1;
}

# Parse a Well-Known-Text (WKT) geometry string into the nested-arrayref
# representation that the Geo column encoders accept. Supported geometries:
# POINT, LINESTRING, MULTILINESTRING, POLYGON, MULTIPOLYGON. Coordinates
# are decimal numbers separated by whitespace; rings/parts are
# parenthesized. The Ring CH type has no WKT name (it is a single closed
# LINESTRING); accept LINESTRING for Ring as well. Returns the structure
# only; the caller chooses which Geo column to feed it into.
sub parse_wkt {
    my ($class, $wkt) = @_;
    die "parse_wkt: input required\n" unless defined $wkt;
    $wkt =~ s/\A\s+//;
    $wkt =~ s/\s+\z//;
    my ($kind, $rest) = $wkt =~ /\A([A-Za-z]+)\s*(.*)\z/s
        or die "parse_wkt: not a WKT geometry: $wkt\n";
    $kind = uc $kind;
    # Strip the outermost parens (which every geometry has) once for
    # uniform downstream parsing. EMPTY is rejected because CH Geo
    # columns have no null/empty representation other than zero-length.
    $rest =~ s/\A\(\s*//
        or die "parse_wkt: $kind missing '(': $wkt\n";
    $rest =~ s/\s*\)\z//
        or die "parse_wkt: $kind unmatched parens: $wkt\n";
    if ($kind eq 'POINT') {
        return _wkt_point($rest);
    }
    if ($kind eq 'LINESTRING') {
        return [ _wkt_points($rest) ];
    }
    if ($kind eq 'MULTILINESTRING' || $kind eq 'POLYGON') {
        # Same shape on the wire (CH Polygon = ring + holes; outer ring
        # comes first; MultiLineString is parallel parts). Parse as a
        # list of paren-wrapped point-lists.
        my @parts;
        while ($rest =~ /\G\s*,?\s*\(\s*([^()]+?)\s*\)/gc) {
            push @parts, [ _wkt_points($1) ];
        }
        die "parse_wkt: $kind: no parts parsed in $wkt\n" unless @parts;
        return \@parts;
    }
    if ($kind eq 'MULTIPOLYGON') {
        my @polys;
        # MULTIPOLYGON(((...),(...)), ((...))): the outer level is
        # polygons, each polygon is a list of rings.
        while ($rest =~ /\G\s*,?\s*\(\s*(.*?)\s*\)\s*(?=,|\z)/gcs) {
            my $poly_body = $1;
            my @rings;
            while ($poly_body =~ /\G\s*,?\s*\(\s*([^()]+?)\s*\)/gc) {
                push @rings, [ _wkt_points($1) ];
            }
            die "parse_wkt: MULTIPOLYGON ring parse failed in $wkt\n"
                unless @rings;
            push @polys, \@rings;
        }
        die "parse_wkt: MULTIPOLYGON: no polygons parsed in $wkt\n"
            unless @polys;
        return \@polys;
    }
    die "parse_wkt: unsupported geometry '$kind'\n";
}

sub _wkt_point {
    my ($s) = @_;
    my @c = split /\s+/, $s;
    die "parse_wkt: POINT needs 2 coords, got '$s'\n" unless @c == 2;
    return [ map { $_ + 0 } @c ];
}

sub _wkt_points {
    my ($s) = @_;
    my @pts;
    for my $pair (split /\s*,\s*/, $s) {
        my @c = split /\s+/, $pair;
        die "parse_wkt: point needs 2 coords, got '$pair'\n" unless @c == 2;
        push @pts, [ map { $_ + 0 } @c ];
    }
    return @pts;
}

# Return the list of supported ClickHouse type names (parametric types
# are listed as their syntactic prefix). For runtime feature detection
# and tooling.
sub types {
    return (qw(
        Int8 Int16 Int32 Int64
        UInt8 UInt16 UInt32 UInt64
        Float32 Float64 BFloat16
        String FixedString
        Date Date32 DateTime DateTime64
        Decimal Decimal32 Decimal64 Decimal128 Decimal256
        Enum8 Enum16
        Bool Boolean UUID IPv4 IPv6
        Array Tuple Nullable Map LowCardinality Variant
        Point Ring LineString MultiLineString Polygon MultiPolygon
        SimpleAggregateFunction
        JSON Object Dynamic
    ));
}

# Compare two column lists, return { added, removed, changed }. Each
# slot holds [name, type] pairs from $b (added/changed) or $a (removed).
# Useful for migration scripts and detecting drift between source and
# destination schemas in CH-to-CH pipelines.
sub schema_diff {
    my ($class, $a, $b) = @_;
    my %a = map { $_->[0] => $_->[1] } @$a;
    my %b = map { $_->[0] => $_->[1] } @$b;
    my (@added, @removed, @changed);
    for my $name (sort keys %b) {
        if (!exists $a{$name}) {
            push @added, [$name, $b{$name}];
        } elsif ($a{$name} ne $b{$name}) {
            push @changed, [$name, $a{$name}, $b{$name}];
        }
    }
    for my $name (sort keys %a) {
        push @removed, [$name, $a{$name}] unless exists $b{$name};
    }
    return { added => \@added, removed => \@removed, changed => \@changed };
}

# Quote a CH identifier (table name, column name) with backticks,
# escaping any backtick within. CH's lexer processes C-style backslash
# escapes inside backtick identifiers, so a literal backslash must be
# escaped too (else `a\` would read as an escaped backtick and the
# identifier would never close). This mirrors ClickHouse's own
# backQuote(): backslash first, then backtick. CH also accepts
# double-quote quoting; we use backticks because show create table does.
sub _quote_ident {
    my $name = shift;
    $name =~ s/\\/\\\\/g;
    $name =~ s/`/\\`/g;
    return "`$name`";
}

# Render one column definition for format_create_table. A column entry
# is [name, type] or [name, type, \%col] where %col may carry
# default/materialized/alias (mutually exclusive), codec, ttl, comment.
# Expression-valued keys are inserted verbatim - the caller owns their
# SQL-correctness; only the comment is quoted (it is the one string
# literal). Clause order matches CH's own `show create table` output;
# keywords are lowercased to match the rest of the generated SQL.
sub _format_column {
    my ($col) = @_;
    my ($name, $type, $extra) = @$col;
    my $sql = _quote_ident($name) . ' ' . $type;
    return $sql unless $extra && ref $extra eq 'HASH';

    my @kind = grep { defined $extra->{$_} }
                    qw(default materialized alias);
    die "format_create_table: column '$name' has more than one of "
      . "default/materialized/alias\n"
        if @kind > 1;
    if (@kind) {
        $sql .= " $kind[0] $extra->{$kind[0]}";
    }
    $sql .= " codec($extra->{codec})"   if defined $extra->{codec};
    $sql .= " ttl $extra->{ttl}"        if defined $extra->{ttl};
    if (defined $extra->{comment}) {
        # CH string literals take C-style backslash escapes; escape the
        # backslash before the quote so an embedded backslash survives.
        (my $c = $extra->{comment}) =~ s/\\/\\\\/g;
        $c =~ s/'/\\'/g;
        $sql .= " comment '$c'";
    }
    return $sql;
}

# Emit a create table statement for the given column list. Table-level
# opts (engine, partition_by, primary_key, order_by, sample_by, ttl,
# settings) are emitted in CH's canonical `show create table` order
# and inserted verbatim - the caller owns SQL correctness there; this
# helper validates only the column list. Per-column
# default/materialized/alias/codec/ttl/comment are supported by passing
# [name, type, \%col] entries. Returns the SQL string (no trailing
# semicolon).
sub format_create_table {
    my ($class, %opts) = @_;
    my $table   = $opts{table}   // die "format_create_table: 'table' required\n";
    my $columns = $opts{columns} // die "format_create_table: 'columns' arrayref required\n";
    my $engine  = $opts{engine}  // 'MergeTree';
    _validate_table_name($table);

    my $body = join ",\n    ", map { _format_column($_) } @$columns;

    my $sql = "create table " . _quote_ident($table) . " (\n    $body\n)";
    $sql .= "\nengine = $engine";
    $sql .= "\npartition by $opts{partition_by}" if defined $opts{partition_by};
    $sql .= "\nprimary key $opts{primary_key}"   if defined $opts{primary_key};
    $sql .= "\norder by $opts{order_by}"         if defined $opts{order_by};
    $sql .= "\nsample by $opts{sample_by}"       if defined $opts{sample_by};
    $sql .= "\nttl $opts{ttl}"                   if defined $opts{ttl};
    $sql .= "\nsettings $opts{settings}"         if defined $opts{settings};
    return $sql;
}

# Translate a schema_diff hashref into a list of alter table statements
# (one per column change). Returns an arrayref of SQL strings; the
# caller decides whether to apply them transactionally or one at a
# time. Conservative ordering: drops first, then modifies, then adds,
# so a column-rename modeled as drop+add ends up with the new column
# at the right position.
sub apply_schema_diff {
    my ($class, $diff, %opts) = @_;
    my $table = $opts{table} // die "apply_schema_diff: 'table' required\n";
    _validate_table_name($table);
    my $qt = _quote_ident($table);
    my @sql;
    for my $row (@{ $diff->{removed} // [] }) {
        push @sql, "alter table $qt drop column "
                 . _quote_ident($row->[0]);
    }
    for my $row (@{ $diff->{changed} // [] }) {
        push @sql, "alter table $qt modify column "
                 . _quote_ident($row->[0]) . " $row->[2]";
    }
    for my $row (@{ $diff->{added} // [] }) {
        push @sql, "alter table $qt add column "
                 . _quote_ident($row->[0]) . " $row->[1]";
    }
    return \@sql;
}

# Unquote a CH identifier: strip surrounding backticks and collapse both
# escape conventions CH's lexer accepts - C-style backslash escapes
# (\X -> X, what backQuote() and _quote_ident emit) and doubled
# backticks (`` -> `). Bare identifiers pass through untouched.
sub _unquote_ident {
    my $s = shift;
    if ($s =~ /\A`(.*)`\z/s) {
        $s = $1;
        $s =~ s/\\(.)|``/defined $1 ? $1 : '`'/ges;
    }
    return $s;
}

# Given the index of an opening backtick in $str, return the index just
# past the matching closing backtick. Honors both escape conventions: a
# backslash escapes the next char, and a doubled `` is a literal
# backtick. Returns length($str) if the quote is never closed. The
# CREATE-TABLE scanners below use this so an escaped backtick inside an
# identifier cannot be mistaken for the end of the quoted region.
sub _skip_backtick_quoted {
    my ($str, $i) = @_;
    my $len = length $str;
    $i++;                                   # past the opening backtick
    while ($i < $len) {
        my $c = substr($str, $i, 1);
        if ($c eq '\\') { $i += 2; next }
        if ($c eq '`') {
            return $i + 1
                unless $i + 1 < $len && substr($str, $i + 1, 1) eq '`';
            $i += 2;                        # doubled-backtick escape
            next;
        }
        $i++;
    }
    return $len;
}

# Split a (possibly backtick-quoted, possibly database-qualified) table
# name into ($database, $table). The qualifying dot is the first one
# that is not inside backticks; a name with no such dot has an undef
# database.
sub _split_qname {
    my ($qname) = @_;
    my $len = length $qname;
    my $dot = -1;
    for (my $i = 0; $i < $len; $i++) {
        my $c = substr($qname, $i, 1);
        if ($c eq '`') { $i = _skip_backtick_quoted($qname, $i) - 1; next }
        if ($c eq '.') { $dot = $i; last }
    }
    return (undef, _unquote_ident($qname)) if $dot < 0;
    return (_unquote_ident(substr($qname, 0, $dot)),
            _unquote_ident(substr($qname, $dot + 1)));
}

# Split a create table column block on top-level commas, respecting both
# parentheses (nested type args) and backtick-quoted identifiers (which
# may legally contain commas or parens). _split_paren_list alone is not
# backtick-aware, hence this dedicated splitter.
sub _split_column_defs {
    my $body = shift;
    my @parts;
    my ($start, $depth, $len) = (0, 0, length $body);
    for (my $i = 0; $i <= $len; $i++) {
        my $c = $i < $len ? substr($body, $i, 1) : ',';
        if ($c eq '`') { $i = _skip_backtick_quoted($body, $i) - 1; next }
        if    ($c eq '(') { $depth++ }
        elsif ($c eq ')') { $depth-- }
        elsif ($c eq ',' && $depth == 0) {
            (my $p = substr($body, $start, $i - $start))
                =~ s/\A\s+|\s+\z//g;
            push @parts, $p if length $p;
            $start = $i + 1;
        }
    }
    return @parts;
}

# Parse the output of `show create table` (or any create table DDL) into
# a structured hashref: { database, table, columns => [[name,type],...],
# engine, order_by, partition_by, primary_key, sample_by, ttl, settings }.
# Clause values are returned verbatim (trimmed); columns is in the same
# [name,type] shape schema_diff and format_create_table consume, so a
# round-trip CH -> parse -> diff -> ALTER is one call each. Per-column
# DEFAULT/CODEC/TTL modifiers are dropped from the type (they are not
# part of the type proper); the bare type is what CH's own `describe`
# would report. Croaks if no create table header or column block is found.
sub parse_create_table {
    my ($class, $ddl) = @_;
    die "parse_create_table: input required\n" unless defined $ddl;

    # A name part is a backtick-quoted identifier or a bare run with no
    # space / dot / paren; the table name is one part, optionally
    # database-qualified with a second. Inside backticks both escape
    # forms are accepted: \X (backslash) and `` (doubled).
    my $part = qr/(?:`(?:[^`\\]|\\.|``)+`|[^\s.(]+)/;
    $ddl =~ /\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:TEMPORARY\s+)?TABLE\s+
             (?:IF\s+NOT\s+EXISTS\s+)?
             ($part (?:\.$part)?)/xgci
        or die "parse_create_table: no create table header found\n";
    my $qname = $1;
    my $name_end = pos $ddl;

    my ($database, $table) = _split_qname($qname);

    # Locate the column block: the first balanced (...) after the name.
    my $open = index $ddl, '(', $name_end;
    die "parse_create_table: no column list found\n" if $open < 0;
    my ($depth, $close, $len) = (0, -1, length $ddl);
    for (my $i = $open; $i < $len; $i++) {
        my $c = substr($ddl, $i, 1);
        if ($c eq '`') { $i = _skip_backtick_quoted($ddl, $i) - 1; next }
        if    ($c eq '(') { $depth++ }
        elsif ($c eq ')') { $depth--; if ($depth == 0) { $close = $i; last } }
    }
    die "parse_create_table: unbalanced column list\n" if $close < 0;
    my $block = substr $ddl, $open + 1, $close - $open - 1;

    my @columns;
    for my $def (_split_column_defs($block)) {
        # Skip table-level INDEX / CONSTRAINT / PROJECTION / primary key
        # entries that share the column block.
        next if $def =~ /\A(?:INDEX|CONSTRAINT|PROJECTION|PRIMARY\s+KEY)\b/i;
        my ($cname, $rest);
        if ($def =~ /\A(`(?:[^`\\]|\\.|``)+`)\s+(.*)\z/s) {
            ($cname, $rest) = (_unquote_ident($1), $2);
        } elsif ($def =~ /\A(\S+)\s+(.*)\z/s) {
            ($cname, $rest) = ($1, $2);
        } else {
            next;
        }
        # The type is the leading identifier plus its balanced (...) args;
        # DEFAULT / CODEC / TTL / COMMENT modifiers come after and are
        # not part of the type.
        my $type = _take_type(\$rest);
        push @columns, [$cname, $type] if length $type;
    }
    die "parse_create_table: no columns parsed\n" unless @columns;

    my $tail = substr $ddl, $close + 1;
    my %out = (
        database => $database,
        table    => $table,
        columns  => \@columns,
    );
    # Trailing clauses. ENGINE has no terminating keyword of its own;
    # each clause runs until the next clause keyword or end of string.
    my $stop = qr/\bENGINE\b|\bPARTITION\s+BY\b|\bPRIMARY\s+KEY\b|
                  \bORDER\s+BY\b|\bSAMPLE\s+BY\b|\bTTL\b|\bSETTINGS\b|\z/xi;
    my %clause = (
        engine       => qr/\bENGINE\s*=\s*/i,
        partition_by => qr/\bPARTITION\s+BY\s+/i,
        primary_key  => qr/\bPRIMARY\s+KEY\s+/i,
        order_by     => qr/\bORDER\s+BY\s+/i,
        sample_by    => qr/\bSAMPLE\s+BY\s+/i,
        ttl          => qr/\bTTL\s+/i,
        settings     => qr/\bSETTINGS\s+/i,
    );
    for my $k (keys %clause) {
        # No /g: each clause is searched from the start of $tail
        # independently. With /g the shared pos() on $tail would make a
        # clause that sorts earlier in the string than a previously
        # matched one unfindable. $+[0] is the end offset of the match.
        next unless $tail =~ $clause{$k};
        my $val = substr $tail, $+[0];
        $val =~ s/$stop.*\z//s;
        $val =~ s/\A\s+|\s+\z//g;
        $out{$k} = $val if length $val;
    }
    return \%out;
}

# Consume one CH type expression from the front of $$rest (an identifier
# optionally followed by a balanced parenthesised argument list), advance
# $$rest past it, and return the type string. Used by parse_create_table
# to separate the type from trailing DEFAULT/CODEC/... modifiers.
sub _take_type {
    my ($rest) = @_;
    $$rest =~ s/\A\s+//;
    return '' unless $$rest =~ /\A([A-Za-z_]\w*)/;
    my $type = $1;
    my $pos  = length $type;
    if (substr($$rest, $pos, 1) eq '(') {
        my ($depth, $len) = (0, length $$rest);
        for (my $i = $pos; $i < $len; $i++) {
            my $c = substr($$rest, $i, 1);
            if ($c eq '`') { $i = _skip_backtick_quoted($$rest, $i) - 1; next }
            if    ($c eq '(') { $depth++ }
            elsif ($c eq ')') { $depth--; if (!$depth) { $pos = $i + 1; last } }
        }
    }
    $type = substr $$rest, 0, $pos;
    substr($$rest, 0, $pos) = '';
    return $type;
}

# Inspect a captured Native block and return its column shape as a
# fresh encoder configured for that shape. Useful for diagnosing
# captured payloads off-line (no server, no schema source) and for
# round-tripping bytes through a transform/filter step. Zero-row
# blocks work fine - the column headers are still on the wire.
sub for_native_bytes {
    my ($class, $bytes) = @_;
    my $blk = $class->decode_block($bytes);
    my @cols;
    for my $col (@{ $blk->{columns} }) {
        push @cols, [ $col->{name}, $col->{type} ];
    }
    return $class->new(columns => \@cols);
}

# --- RowBinary -------------------------------------------------------
#
# RowBinary is ClickHouse's row-major binary format: each row is the
# concatenation of its column values, with no headers. The per-value
# byte encoding for scalar / String / FixedString / Nullable columns is
# byte-identical to that column's data in a one-row Native block, so
# encode_row_binary reuses the XS Native encoder and slices the value
# region out; decode_row_binary wraps a value back into a one-row Native
# block and runs the XS decoder. Array(T) is the one shape that differs
# (RowBinary uses a varint element count where Native uses a UInt64
# offset) and is handled by recursion. This keeps a single source of
# truth for every type's wire bytes - no second per-type codec in Perl.
#
# Supported: all scalar types (Int*/UInt*/Float*/Bool/Date*/DateTime*/
# Decimal*/UUID/IPv4/IPv6/Enum*), String, FixedString(N), Nullable of
# any of those, Array(...) nesting, and LowCardinality(...) (encoded as
# its inner type, which is how RowBinary represents it). Map, Tuple,
# Variant, JSON, Dynamic, Geo and Nested croak - their Native and
# RowBinary framings diverge in ways the slice trick cannot bridge.

# Fixed on-wire byte width per scalar base type (parametric suffix
# already stripped by the caller). Decimal/FixedString are sized
# separately because their width depends on the type parameters.
my %RB_FIXED_WIDTH = (
    Int8 => 1, UInt8 => 1, Bool => 1, Boolean => 1, Enum8 => 1,
    Int16 => 2, UInt16 => 2, Date => 2, Enum16 => 2,
    Int32 => 4, UInt32 => 4, Float32 => 4, BFloat16 => 2,
    Date32 => 4, DateTime => 4, IPv4 => 4, Decimal32 => 4,
    Int64 => 8, UInt64 => 8, Float64 => 8, DateTime64 => 8,
    Decimal64 => 8,
    Int128 => 16, UInt128 => 16, UUID => 16, IPv6 => 16, Decimal128 => 16,
    Int256 => 32, UInt256 => 32, Decimal256 => 32,
);

# Croak unless $type is a RowBinary-supported scalar (or Nullable of
# one). Array / LowCardinality are peeled by the caller before this
# runs, so anything parenthesised-and-recursive that reaches here is
# unsupported.
sub _rb_assert_scalar {
    my ($type) = @_;
    # ClickHouse does not nest Nullable, so a single peel is enough.
    my $t = $type;
    $t = $1 if $t =~ /\ANullable\((.+)\)\z/s;
    die "row_binary: type '$type' is not supported (RowBinary covers "
      . "scalar/String/FixedString columns, optionally Nullable, "
      . "Array, or LowCardinality)\n"
        if $t =~ /\A(?:Map|Tuple|Variant|JSON|Object|Dynamic|Point|Ring
                     |LineString|MultiLineString|Polygon|MultiPolygon
                     |Nested|SimpleAggregateFunction|AggregateFunction
                     |Array|LowCardinality)\b/x;
    return;
}

# The varint / length-string codecs are XS, registered into the
# ClickHouse::Encoder::TCP package (the protocol packers use them);
# the single shared object installs them regardless of package, so
# they are callable here once the main module's XS has booted. Alias
# them in as glob aliases (not wrapper subs) so a call goes straight
# to the XSUB with no extra frame and exact context propagation.
## no critic (ProhibitCallsToUnexportedSubs)
*_rb_pack_varint   = \&ClickHouse::Encoder::TCP::pack_varint;
*_rb_unpack_varint = \&ClickHouse::Encoder::TCP::unpack_varint;
*_rb_pack_string   = \&ClickHouse::Encoder::TCP::pack_string;
## use critic

# Encode one value of $type into RowBinary bytes. $cache memoises the
# single-column Native encoder + value-region offset per scalar type.
sub _rb_encode_value {
    my ($type, $val, $cache) = @_;
    if ($type =~ /\AArray\((.+)\)\z/s) {
        my $inner = $1;
        die "encode_row_binary: Array column needs an arrayref value\n"
            unless ref $val eq 'ARRAY';
        my $s = _rb_pack_varint(scalar @$val);
        $s .= _rb_encode_value($inner, $_, $cache) for @$val;
        return $s;
    }
    if ($type =~ /\ALowCardinality\((.+)\)\z/s) {
        return _rb_encode_value($1, $val, $cache);
    }
    _rb_assert_scalar($type);
    my $slot = $cache->{$type} ||= do {
        my $enc = ClickHouse::Encoder->new(columns => [['c', $type]]);
        # One-row, one-column Native block prefix:
        #   varint(ncols=1) varint(nrows=1) lenstr("c") lenstr(type)
        my $prefix = 2 + length(_rb_pack_string('c'))
                       + length(_rb_pack_string($type));
        [$enc, $prefix];
    };
    return substr($slot->[0]->encode([[ $val ]]), $slot->[1]);
}

# Encode an arrayref of rows into a RowBinary byte string. Call on an
# encoder instance (its column types drive serialisation). The result
# is the request body for `insert ... format RowBinary`.
sub encode_row_binary {
    my ($self, $rows) = @_;
    die "encode_row_binary: rows must be an arrayref\n"
        unless ref $rows eq 'ARRAY';
    my $cols = $self->columns;
    my %cache;
    my $out = '';
    for my $ri (0 .. $#$rows) {
        my $row = $rows->[$ri];
        die "encode_row_binary: row $ri must be an arrayref\n"
            unless ref $row eq 'ARRAY';
        die "encode_row_binary: row $ri has " . scalar(@$row)
          . " values, expected " . scalar(@$cols) . "\n"
            unless @$row == @$cols;
        for my $ci (0 .. $#$cols) {
            $out .= _rb_encode_value($cols->[$ci][1], $row->[$ci], \%cache);
        }
    }
    return $out;
}

# Byte length of one scalar/String/FixedString/Nullable value at
# $$bufref position $pos (does not advance). Array is handled by the
# caller's recursion, never reaching here.
sub _rb_value_len {
    my ($type, $bufref, $pos) = @_;
    if ($type =~ /\ANullable\((.+)\)\z/s) {
        return 1 + _rb_value_len($1, $bufref, $pos + 1);
    }
    if ($type =~ /\ALowCardinality\((.+)\)\z/s) {
        return _rb_value_len($1, $bufref, $pos);
    }
    if ($type eq 'String') {
        my ($len, $after) = _rb_unpack_varint($$bufref, $pos);
        return ($after - $pos) + $len;
    }
    if ($type =~ /\AFixedString\((\d+)\)\z/) {
        return $1;
    }
    (my $base = $type) =~ s/\(.*//s;
    if ($base eq 'Decimal') {
        # Decimal(P, S): storage width follows the precision P.
        my ($p) = $type =~ /\(\s*(\d+)/;
        return $p <= 9  ? 4  : $p <= 18 ? 8
             : $p <= 38 ? 16 : 32;
    }
    my $w = $RB_FIXED_WIDTH{$base};
    die "decode_row_binary: cannot size unsupported type '$type'\n"
        unless defined $w;
    return $w;
}

# Decode one value of $type at $$posref, advancing $$posref past it.
sub _rb_decode_value {
    my ($type, $bufref, $posref, $cache) = @_;
    if ($type =~ /\AArray\((.+)\)\z/s) {
        my $inner = $1;
        my ($n, $after) = _rb_unpack_varint($$bufref, $$posref);
        $$posref = $after;
        return [ map { _rb_decode_value($inner, $bufref, $posref, $cache) }
                 1 .. $n ];
    }
    if ($type =~ /\ALowCardinality\((.+)\)\z/s) {
        return _rb_decode_value($1, $bufref, $posref, $cache);
    }
    _rb_assert_scalar($type);
    my $vlen   = _rb_value_len($type, $bufref, $$posref);
    my $vbytes = substr($$bufref, $$posref, $vlen);
    die "decode_row_binary: truncated value for '$type' at offset $$posref\n"
        if length($vbytes) != $vlen;
    $$posref += $vlen;
    my $prefix = $cache->{$type} ||=
        "\x01\x01" . _rb_pack_string('c') . _rb_pack_string($type);
    my $blk = ClickHouse::Encoder->decode_block($prefix . $vbytes);
    return $blk->{columns}[0]{values}[0];
}

# Decode a RowBinary byte string into an arrayref of row arrayrefs.
# Call on an encoder instance whose column types match the producer.
sub decode_row_binary {
    my ($self, $bytes) = @_;
    die "decode_row_binary: must be called on an encoder instance\n"
        unless ref $self;
    die "decode_row_binary: input must be defined\n" unless defined $bytes;
    my $cols = $self->columns;
    my $pos  = 0;
    my $len  = length $bytes;
    # With zero columns the inner per-column loop is a no-op, so a
    # non-empty buffer would never make $pos advance - guard explicitly
    # rather than spin forever.
    die "decode_row_binary: encoder has no columns but $len bytes given\n"
        if !@$cols && $len;
    my %cache;
    my @rows;
    while ($pos < $len) {
        my @row;
        for my $col (@$cols) {
            push @row, _rb_decode_value($col->[1], \$bytes, \$pos, \%cache);
        }
        push @rows, \@row;
    }
    return \@rows;
}

# Post-process a decoded block (or any one column's values arrayref):
# rewrite Date / Date32 / DateTime / DateTime64 integer epochs into
# ISO 8601 strings or Time::Moment instances. Modifies the block in
# place AND returns it so the call can be chained. as => 'iso' (the
# default) emits UTC strings with a 'Z' suffix; as => 'datetime'
# returns Time::Moment objects (requires Time::Moment installed).
# DateTime64 precision is read from the column's type string so each
# tick converts to the correct number of fractional digits.
sub coerce_datetimes {
    my ($class_or_self, $block, %opts) = @_;
    my $as = $opts{as} // 'iso';
    die "coerce_datetimes: 'as' must be 'iso' or 'datetime' (got '$as')\n"
        unless $as eq 'iso' || $as eq 'datetime';

    if ($as eq 'datetime') {
        require Time::Moment;
    } else {
        require POSIX;
    }

    for my $col (@{ $block->{columns} }) {
        next if $col->{skipped};
        my $type = $col->{type};
        my $vals = $col->{values};

        # Strip Nullable() wrapping so the inner type matches below.
        # Nullable values come through as undef in the values array;
        # the loops already skip undef.
        $type = $1 if $type =~ /^Nullable\((.*)\)\z/;

        if ($type eq 'Date' || $type eq 'Date32') {
            for my $v (@$vals) {
                next unless defined $v;
                $v = _epoch_to_string($v * 86400, 0, $as, 'Y-m-d');
            }
        }
        elsif ($type eq 'DateTime' || $type =~ /^DateTime\(/) {
            for my $v (@$vals) {
                next unless defined $v;
                $v = _epoch_to_string($v, 0, $as, 'iso');
            }
        }
        elsif ($type =~ /^DateTime64\((\d+)/) {
            my $precision = $1;
            my $scale     = 10 ** $precision;
            for my $v (@$vals) {
                next unless defined $v;
                # Decoded DateTime64 is an integer count of (10^precision)
                # ticks since the Unix epoch (a signed int64).
                use integer;
                my $secs  = int($v / $scale);
                no integer;
                my $frac  = $v - $secs * $scale;
                # Normalize negative fractional tail to a positive frac
                # below the integer epoch.
                if ($frac < 0) { $frac += $scale; $secs -= 1 }
                $v = _epoch_to_string($secs, $frac, $as,
                                       'iso', $precision);
            }
        }
        # other columns (non-time) untouched
    }
    return $block;
}

# Format a (whole_seconds, fractional_ticks_at_$precision) pair under
# either 'iso' or 'datetime' modes. Internal helper; the strftime is
# UTC-only on purpose (CH itself stores UTC ticks; per-column timezone
# is a display concern handled separately by the user if needed).
sub _epoch_to_string {
    my ($secs, $frac_ticks, $as, $shape, $precision) = @_;
    if ($as eq 'datetime') {
        if ($shape ne 'Y-m-d' && $precision) {
            # Time::Moment uses nanosecond precision; widen the ticks
            # accordingly. Precision > 9 isn't supported here.
            my $ns = $frac_ticks * (10 ** (9 - $precision));
            return Time::Moment->from_epoch($secs, $ns);
        }
        return Time::Moment->from_epoch($secs);
    }
    # 'iso' string form
    my @t = gmtime $secs;
    if ($shape eq 'Y-m-d') {
        return POSIX::strftime('%Y-%m-%d', @t);
    }
    my $base = POSIX::strftime('%Y-%m-%dT%H:%M:%S', @t);
    if ($precision) {
        $base .= sprintf('.%0*d', $precision, $frac_ticks);
    }
    return $base . 'Z';
}

# Static per-type byte budgets used by estimate_size. Returns the
# bytes-per-row for fixed-width types; for variable types the second
# return value is an "average string size" heuristic the caller can
# use, and undef means "walk the actual values for accuracy". The
# table is intentionally coarse - the goal is order-of-magnitude
# sizing for batch-split decisions, not byte-exact accounting.
my %FIXED_TYPE_BYTES = (
    Int8 => 1, UInt8 => 1, Bool => 1, Boolean => 1,
    Int16 => 2, UInt16 => 2, Date => 2,
    Int32 => 4, UInt32 => 4, Float32 => 4, BFloat16 => 2,
    Date32 => 4, DateTime => 4, IPv4 => 4, Decimal32 => 4,
    Enum8 => 1, Enum16 => 2,
    Int64 => 8, UInt64 => 8, Float64 => 8, DateTime64 => 8,
    Decimal64 => 8,
    UUID => 16, IPv6 => 16, Decimal128 => 16,
    Decimal256 => 32,
    # Geo aliases:
    Point => 16, Ring => 64, LineString => 64,
    MultiLineString => 256, Polygon => 256, MultiPolygon => 256,
);

sub _type_byte_estimate {
    my ($type, $avg_str) = @_;
    $avg_str //= 16;
    # Strip outer parens/args for parametric prefix match.
    my $base = $type;
    $base =~ s/\(.*\z//s;
    return $FIXED_TYPE_BYTES{$base} if exists $FIXED_TYPE_BYTES{$base};

    if ($base eq 'String') {
        return $avg_str + 1;  # +1 for varint length prefix (small lens)
    }
    if ($base eq 'FixedString') {
        my ($n) = $type =~ /^FixedString\((\d+)\)/;
        return $n // $avg_str;
    }
    if ($base eq 'Nullable') {
        my ($inner) = $type =~ /^Nullable\((.+)\)$/;
        return 1 + _type_byte_estimate($inner, $avg_str);
    }
    if ($base eq 'Array' || $base eq 'Map') {
        # 8-byte offset per row + N_avg(=4) inner elements.
        my ($inner) = $type =~ /^\w+\((.+)\)$/;
        return 8 + 4 * _type_byte_estimate($inner, $avg_str);
    }
    if ($base eq 'Tuple') {
        my ($body) = $type =~ /^Tuple\((.+)\)$/;
        return 0 unless defined $body;
        my @parts = _split_paren_list($body);
        my $sum = 0;
        for my $p (@parts) {
            # Tuple elements may be named: "name Type"
            $p =~ s/^[A-Za-z_]\w*\s+//;
            $sum += _type_byte_estimate($p, $avg_str);
        }
        return $sum;
    }
    # LowCardinality: dict + per-row 1-byte index (typical low cardinality).
    # Variant: 1 disc byte + (heuristically) inner avg.
    return 1 + $avg_str if $base eq 'LowCardinality' || $base eq 'Variant';
    # JSON/Object/Dynamic: shape-dependent. Heuristic: roughly two
    # avg_string_size payloads per row (one for path machinery + one
    # for value bytes), so the caller's avg_string_size override
    # actually moves the estimate.
    return 2 * $avg_str if $base eq 'JSON' || $base eq 'Object' || $base eq 'Dynamic';
    # SimpleAggregateFunction(func, T) -> inner T.
    if ($base eq 'SimpleAggregateFunction') {
        my ($inner) = $type =~ /^SimpleAggregateFunction\([^,]+,\s*(.+)\)$/;
        return _type_byte_estimate($inner, $avg_str) if defined $inner;
    }
    return $avg_str;  # unknown -> conservative
}

# Coarse byte-size estimate for an encoded block, parameterized on
# row count (an integer) or arrayref (counted). Uses per-type byte
# budgets; variable-length types use a 16-byte average per value
# (override via $avg_str). For batch-size decisions ("is this 1 MiB
# or 100 MiB before I compress?"). NOT byte-exact: a String row with
# a 10 KiB blob will be undercounted. Run encode() for the real size.
sub estimate_size {
    my ($self, $rows_or_n, %opts) = @_;
    my $n = ref $rows_or_n eq 'ARRAY' ? scalar @$rows_or_n : $rows_or_n;
    my $avg_str = $opts{avg_string_size} // 16;
    my $cols = $self->columns;
    my $total = 4;  # block header (ncols + nrows varints, ~tiny)
    for my $c (@$cols) {
        my ($name, $type) = @$c;
        $total += length($name) + length($type) + 2;   # lenstr headers
        $total += $n * _type_byte_estimate($type, $avg_str);
    }
    return $total;
}

# Return a configured encoder for the column shape produced by an
# arbitrary select. Runs `describe ($sql)` via the same `via=>...`
# transport as for_table. Useful when the schema isn't a real table.
sub for_query {
    my ($class, $sql, %opts) = @_;
    # ClickHouse's describe accepts a subquery, but the SQL must not
    # contain unmatched parentheses; let the server reject malformed
    # queries rather than re-implementing SQL validation here.
    my $describe = "describe ($sql)";
    return $class->_for_describe($describe, %opts);
}

# Issue an insert ... format native over HTTP using HTTP::Tiny. Returns
# the response hashref from HTTP::Tiny (->{success}, ->{status},
# ->{content}). Compresses with zstd/gzip if `compress` is set; takes
# whatever encoder produces (so `for_table` + rows is the typical
# combination). Does not retry; the caller does HTTP-level error policy.
# Set up URL + headers for an insert ... format native HTTP request.
# Shared by insert_http and BulkInserter::new. Validates the table name
# and stamps the Content-Type / Content-Encoding headers as needed.
sub _build_insert_endpoint {
    my ($table, $compress, %args) = @_;
    _validate_table_name($table);
    die "unknown compress='$compress' "
      . "(expected 'raw', 'zstd', or 'gzip')\n"
        unless $compress eq 'raw' || $compress eq 'zstd'
            || $compress eq 'gzip';
    my ($url, $hdr) = _http_url_headers(
        "insert into $table format native", %args);
    $hdr->{'Content-Type'} = 'application/octet-stream';
    $hdr->{'Content-Encoding'} = $compress
        if $compress eq 'zstd' || $compress eq 'gzip';
    return ($url, $hdr);
}

# Apply zstd/gzip compression to $body in place (or pass through for 'raw').
# $compress is validated upstream by _build_insert_endpoint; we trust it
# here. $origin is the class used to resolve compressed_writer (so the
# helper works for class-method and instance callers alike).
sub _apply_compression {
    my ($origin, $compress, $body) = @_;
    return $body if $compress eq 'raw';
    my $compressed;
    my $wrap = $origin->compressed_writer(
        $compress, sub { $compressed = $_[0] });
    $wrap->($body);
    return $compressed;
}

sub insert_http {
    my ($class_or_self, %args) = @_;
    my $enc      = $args{encoder} // do {
        my $cols = $args{columns} or die "insert_http needs columns or encoder";
        $class_or_self->new(columns => $cols);
    };
    my $rows     = $args{rows}  or die "insert_http needs rows arrayref";
    my $table    = $args{table} or die "insert_http needs table";
    my $timeout  = $args{timeout}  // 60;
    my $compress = $args{compress} // 'raw';
    my $origin   = ref $class_or_self || $class_or_self;

    my ($url, $hdr) = _build_insert_endpoint($table, $compress, %args);
    my $body = _apply_compression($origin, $compress, $enc->encode($rows));

    my $resp = _http_tiny(%args, timeout => $timeout)
        ->post($url, { headers => $hdr, content => $body });
    return _decorate_response($resp);
}

# Stream a select response: POST the SQL with default_format=Native,
# feed the response chunks into a sliding buffer, decode complete blocks
# as they arrive, and pass each one to $opts{on_block}. Memory stays
# bounded by chunk_size + one block, so this is the right entry point
# for selects that won't fit in memory. The user's $sql must NOT include
# a format clause - this helper always requests format Native.
sub select_blocks {
    my ($class, $sql, %opts) = @_;
    my $cb   = $opts{on_block}
        or die "select_blocks: 'on_block' coderef required\n";
    die "select_blocks: \$sql should not include a format clause "
      . "(select_blocks always requests format Native)\n"
        if $sql =~ /\bformat\s+\w+\s*\z/i;
    my $keep        = $opts{keep};
    my $decompress  = $opts{decompress};

    # Build URL+headers via the same helper insert_http uses, but with an
    # empty SQL placeholder; we POST the SQL as the request body. Adding
    # default_format=Native ensures the response is Native bytes even if
    # the user's SQL doesn't terminate with format.
    my %h_opts = %opts;
    # Drop keys this method consumes; also drop dedup_token, which is
    # meaningful only on insert (would be silently dead weight on the
    # select URL otherwise and could mask a typo by the caller).
    delete @h_opts{qw(on_block keep timeout decompress dedup_token)};
    my ($url, $hdr) = _http_url_headers('', %h_opts);
    $url .= '&default_format=Native';
    # When decompress=1 is requested the server wraps each Native block
    # in its compressed-block framing (X-ClickHouse-Compressed header).
    # Add ?compress=1 to the URL so CH knows to compress the response.
    $url .= '&compress=1' if $decompress;

    my $buf = '';
    # Block walker: when decompress is set, walk through compressed-block-
    # framing entries and feed the decompressed bytes into a second
    # accumulator that decode_block reads. Otherwise feed buf directly.
    my $inner_buf = '';
    my $drain = sub {
        # Phase 1: pull compressed-block frames out of $buf into $inner_buf
        if ($decompress) {
            while (length($buf) >= 25) {     # 16 hash + 9 header minimum
                my $csize = unpack 'V', substr($buf, 17, 4);
                last if length($buf) < 16 + $csize;
                my ($plain, $consumed) =
                    $class->decompress_native_block($buf);
                $inner_buf .= $plain;
                substr($buf, 0, $consumed, '');
            }
        } else {
            $inner_buf = $buf;
        }
        # Phase 2: decode whole Native blocks out of $inner_buf
        while (length($inner_buf) > 0) {
            my $block = eval { $class->decode_block($inner_buf, 0, $keep) };
            if ($@) {
                last if $@ =~ /buffer truncated/i;
                die $@;
            }
            $cb->($block);
            substr($inner_buf, 0, $block->{consumed}, '');
        }
        # When not decompressing, inner_buf IS buf; carry the residual
        # back so the next data_callback append sees the unconsumed tail.
        if (!$decompress) {
            $buf = $inner_buf;
        }
    };

    my $resp = _http_tiny(%opts, timeout => $opts{timeout} // 60)->post(
        $url,
        { content => $sql,
          headers => { %$hdr, 'Content-Type' => 'text/plain' },
          data_callback => sub { $buf .= $_[0]; $drain->() },
        });

    die "select_blocks: HTTP $resp->{status}: $resp->{content}\n"
        unless $resp->{success};

    $drain->();
    die "select_blocks: " . length($buf) . " trailing bytes "
      . "after last complete compressed block\n"
        if $decompress && length $buf;
    die "select_blocks: " . length($inner_buf) . " trailing bytes "
      . "after last complete block\n"
        if length $inner_buf;
    return;
}

# Returns a bulk-inserter object: ->push($row), ->push_many(\@rows),
# ->flush (idempotent), ->finish. Holds a single HTTP::Tiny instance
# across batches (so keepalive applies) and auto-flushes when the
# accumulated row count crosses batch_size. Transient HTTP failures
# (5xx, network errors) are retried up to retries times with linear
# backoff; 4xx errors die immediately.
sub bulk_inserter {
    my ($class_or_self, %args) = @_;
    return ClickHouse::Encoder::BulkInserter->new(%args,
        _origin => $class_or_self);
}

package ClickHouse::Encoder::BulkInserter;  ## no critic (ProhibitMultiplePackages)

sub new {
    my ($class, %args) = @_;
    my $origin_raw = delete $args{_origin};
    my $origin     = (ref $origin_raw || $origin_raw) || 'ClickHouse::Encoder';
    my $enc        = $args{encoder} // do {
        my $cols = $args{columns} or die "bulk_inserter needs columns or encoder";
        $origin->new(columns => $cols);
    };
    my $table      = $args{table} or die "bulk_inserter needs table";
    my $compress   = $args{compress} // 'raw';
    my $timeout    = $args{timeout}  // 60;

    my ($url, $hdr) = ClickHouse::Encoder::_build_insert_endpoint(
        $table, $compress, %args);

    return bless {
        enc        => $enc,
        url        => $url,
        hdr        => $hdr,
        rows       => [],
        batch_size => $args{batch_size} // 10_000,
        retries    => $args{retries}    // 3,
        retry_wait => $args{retry_wait} // 0.5,
        retry_max_wait => $args{retry_max_wait} // 30,
        compress   => $compress,
        http       => ClickHouse::Encoder::_http_tiny(
            %args, timeout => $timeout, keep_alive => 1),
        origin     => $origin,
        sent_rows  => 0,
        sent_batches => 0,
        last_response => undef,
        summary    => {},
    }, $class;
}

sub push :method {  ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $row) = @_;
    CORE::push @{ $self->{rows} }, $row;
    $self->flush if @{ $self->{rows} } >= $self->{batch_size};
    return $self;
}

sub push_many {
    my ($self, $rows) = @_;
    CORE::push @{ $self->{rows} }, @{$rows};
    # Slice exactly batch_size rows per flush so we never POST one
    # oversized body when push_many is called with N >> batch_size.
    # `local` restores $self->{rows} to the remainder arrayref even
    # when `flush` croaks mid-batch (so caller's eval{} sees the
    # untried rows still buffered for a retry).
    while (@{ $self->{rows} } > $self->{batch_size}) {
        my @batch = splice @{ $self->{rows} }, 0, $self->{batch_size};
        local $self->{rows} = \@batch;
        $self->flush;
    }
    $self->flush if @{ $self->{rows} } >= $self->{batch_size};
    return $self;
}

sub flush {
    my $self = shift;
    my $rows = $self->{rows};
    return $self if !@{$rows};
    my $body = ClickHouse::Encoder::_apply_compression(
        $self->{origin}, $self->{compress}, $self->{enc}->encode($rows));
    my $resp;
    my $last_err;
    for my $attempt (0 .. $self->{retries}) {
        $resp = $self->{http}->post($self->{url},
            { headers => $self->{hdr}, content => $body });
        last if $resp->{success};
        # 4xx errors are not retryable - the request is malformed.
        die "bulk_inserter: HTTP $resp->{status}: $resp->{content}\n"
            if $resp->{status} >= 400 && $resp->{status} < 500;
        $last_err = "HTTP $resp->{status}: $resp->{content}";
        # 5xx and network failures (599) are retryable. Exponential
        # backoff (retry_wait * 2^attempt, capped at retry_max_wait)
        # with equal jitter: sleep half the window deterministically
        # then a random half, so concurrent inserters retrying the
        # same failed server don't resynchronise into a thundering herd.
        if ($attempt < $self->{retries}) {
            require Time::HiRes;
            my $window = $self->{retry_wait} * (2 ** $attempt);
            $window = $self->{retry_max_wait}
                if $window > $self->{retry_max_wait};
            Time::HiRes::sleep($window / 2 + rand($window / 2));
        }
    }
    die "bulk_inserter: gave up after $self->{retries} retries; "
      . "last error: $last_err\n"
        unless $resp->{success};
    ClickHouse::Encoder::_decorate_response($resp);
    $self->{last_response} = $resp;
    if (my $sum = $resp->{ch}{summary}) {
        # Roll up CH summary fields across batches (read_rows,
        # written_rows, written_bytes, elapsed_ns, ...). Caller uses
        # ->summary to get the running totals; ->last_response to get
        # the most recent per-batch detail.
        $self->{summary}{$_} = ($self->{summary}{$_} // 0) + $sum->{$_}
            for grep { $sum->{$_} =~ /\A-?\d+\z/ } keys %$sum;
    }
    $self->{rows} = [];
    $self->{sent_rows} += @{$rows};
    $self->{sent_batches}++;
    return $self;
}

sub last_response { my $self = shift; return $self->{last_response} }
sub summary       { my $self = shift; return $self->{summary} }

sub finish {
    my $self = shift;
    $self->flush;
    return { rows => $self->{sent_rows}, batches => $self->{sent_batches} };
}

sub buffered_count { my $self = shift; return scalar @{ $self->{rows} } }
sub sent_rows      { my $self = shift; return $self->{sent_rows} }
sub sent_batches   { my $self = shift; return $self->{sent_batches} }

package ClickHouse::Encoder;  ## no critic (ProhibitMultiplePackages)

# Decimal128 values returned by decode_block come as [lo_uint64,
# hi_int64]; Decimal256 as a 4-limb arrayref. Use Math::BigInt to
# stitch limbs into a scaled decimal string.
sub decimal128_str {
    my ($class, $lo, $hi, $scale) = @_;
    require Math::BigInt;
    my $two64 = Math::BigInt->new(1)->blsft(64);
    my $v = Math::BigInt->new($hi)->bmul($two64)->badd($lo);
    return _scale_int_to_str($v, $scale);
}

sub decimal256_str {
    my ($class, $limbs, $scale) = @_;
    require Math::BigInt;
    my $two64 = Math::BigInt->new(1)->blsft(64);
    # Top limb (limbs[3]) is the sign-extended high quarter. The sign
    # check uses BigInt comparisons; native Perl `1 << 64` returns 0 on
    # a 64-bit Perl (shift past word width), which would silently turn
    # a negative value into a wrong positive one.
    my $top    = Math::BigInt->new($limbs->[3]);
    my $two63  = Math::BigInt->new(1)->blsft(63);
    $top->bsub($two64) if $top >= $two63;
    my $v = $top;
    $v->bmul($two64)->badd(Math::BigInt->new($limbs->[2]));
    $v->bmul($two64)->badd(Math::BigInt->new($limbs->[1]));
    $v->bmul($two64)->badd(Math::BigInt->new($limbs->[0]));
    return _scale_int_to_str($v, $scale);
}

sub _scale_int_to_str {
    my ($big, $scale) = @_;
    my $sign = $big->is_neg ? '-' : '';
    my $abs  = $big->copy->babs->bstr;
    return "$sign$abs" if !$scale || $scale == 0;
    $abs = ('0' x ($scale - length($abs) + 1)) . $abs
        if length($abs) <= $scale;
    return $sign . substr($abs, 0, length($abs) - $scale)
                 . '.'
                 . substr($abs, length($abs) - $scale);
}

# Convenience: open `@cmd` as a write pipe, encode rows into it, and
# close. Croaks on fork failure, exec failure, or non-zero child exit.
# Used by examples piping into
# `clickhouse-client insert ... format native`.
sub encode_to_command {
    my ($self, $cmd, $rows) = @_;
    ref $cmd eq 'ARRAY' or die "encode_to_command: cmd must be arrayref";
    @$cmd or die "encode_to_command: cmd must be non-empty arrayref";

    # Without ignoring SIGPIPE, an early child exit (e.g. clickhouse-client
    # rejecting the schema) would kill the parent silently with status
    # 141 instead of producing a trappable diagnostic on close.
    local $SIG{PIPE} = 'IGNORE';

    ## no critic (InputOutput::RequireBriefOpen) -- $fh is closed below
    defined(my $pid = open my $fh, '|-') or die "fork: $!";
    if ($pid == 0) {
        # exec only returns on failure. Fold the failure path onto the
        # same statement (via `or do {...}`) so Perl doesn't flag the
        # post-exec code as unreachable at compile time. POSIX::_exit
        # (not die or plain exit) skips END blocks and DESTROY handlers
        # inherited from the parent; syswrite avoids running PerlIO
        # layers and __WARN__ handlers. Suppress Perl's default "Can't
        # exec" warning so the only diagnostic comes from our syswrite.
        no warnings 'exec';  ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        exec { $cmd->[0] } @$cmd or do {
            my $err = $!;
            require POSIX;
            syswrite STDERR, "exec @$cmd: $err\n";
            POSIX::_exit(127);
        };
    }
    binmode $fh;
    $self->encode_to_handle($fh, $rows);
    close $fh
        or die "@$cmd " . ($! ? "close: $!" : "exit " . ($? >> 8));
    return;
}

1;

__END__

=head1 NAME

ClickHouse::Encoder - Fast XS encoder for ClickHouse Native format

=head1 SYNOPSIS

    use ClickHouse::Encoder;

    # 1. Encode rows into a Native-format block --------------------
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id',     'UInt64'],
        ['user',   'String'],
        ['tags',   'Array(String)'],
        ['score',  'Nullable(Float64)'],
        ['stamp',  'DateTime'],
    ]);
    my $body = $enc->encode([
        [1, 'alice', ['perl','db'], 0.95, time()],
        [2, 'bob',   [],            undef, time()],
    ]);
    # $body is the request body for `insert into events format native`.

    # 2. Decode a select ... format native response ----------------
    my $response_body = '...';  # HTTP body of select * format native
    my $blocks = ClickHouse::Encoder->decode_blocks($response_body);
    for my $blk (@$blocks) {
        for my $r (0 .. $blk->{nrows} - 1) {
            my %row = map { $_->{name} => $_->{values}[$r] }
                          @{ $blk->{columns} };
            ...;
        }
    }

    # 3. Bulk insert with auto-flush + retries ---------------------
    my $bi = ClickHouse::Encoder->bulk_inserter(
        host => 'db', table => 'events',
        columns => [['ev','String'],['ts','DateTime']],
        batch_size => 5000, compress => 'zstd');
    my @events = ('login', 'click', 'logout');  # or any iterable
    $bi->push([$_, time()]) for @events;
    $bi->finish;

    # 4. JSON columns (CH 24.8+) -----------------------------------
    use JSON::PP ();  # for ::true / ::false
    my $jenc = ClickHouse::Encoder->new(columns => [['j','JSON']]);
    my $jbody = $jenc->encode([
        [{ user => { name => 'alice', id => 42 },
           active => JSON::PP::true }],
        [{ user => { name => 'bob' }, tags => ['a','b'] }],
    ]);

    # 5. Streaming select, with response compression ---------------
    ClickHouse::Encoder->select_blocks(
        'select id, event, ts from events where date = today()',
        host => 'db', port => 8123,
        decompress => 1,                  # CH wraps each block in LZ4
        keep => { id => 1, event => 1 },  # optional column projection
        on_block => sub {
            my $blk = shift;
            # Optional: coerce DateTime / Date columns to ISO strings.
            ClickHouse::Encoder->coerce_datetimes($blk);
            for my $r (0 .. $blk->{nrows} - 1) {
                print "row $r: ", join(' | ',
                    map { $_->{values}[$r] // 'NULL' }
                    grep { !$_->{skipped} } @{ $blk->{columns} }), "\n";
            }
        });

=head1 DESCRIPTION

Builds a block in ClickHouse's
L<Native|https://clickhouse.com/docs/en/interfaces/formats#native>
columnar binary format from a Perl arrayref of rows. The returned scalar is
the raw body for an C<insert ... format native> request: send it over HTTP,
the native TCP protocol, or pipe it into C<clickhouse-client>.

Construct one encoder per schema and reuse it across batches: type parsing
happens up front, encoding is pure XS, and failed encodes never leak the
partial buffer.

=head1 METHODS

=head2 new

    my $enc = ClickHouse::Encoder->new(columns => \@columns);

C<columns> is an arrayref of C<[$name, $type]> pairs. The C<$type> string
must match the syntax ClickHouse uses in C<describe table> output (see
L</TYPES>).

Croaks on unknown or malformed types, on C<Nullable(Nullable(...))>, on
empty enum names, on enum values out of range, on C<FixedString(0)>, and
on out-of-range C<Decimal*> / C<DateTime64> parameters.

=head2 encode

    my $bytes = $enc->encode(\@rows);

Returns the raw bytes of one Native-format block. C<\@rows> is an arrayref
of arrayrefs; each inner arrayref must have exactly as many elements as the
encoder's columns. Croaks if a row's shape is wrong, if a value can't be
coerced to its column type, or on string parse errors (see L</Value
coercion>).

=head2 encode_columns

    my $bytes = $enc->encode_columns({
        id   => [1, 2, 3],
        name => ['a', 'b', 'c'],
    });

Like L</encode> but takes a column-oriented hashref
C<<< { name => \@values } >>>. Skips the row-to-column permutation step
that C<encode> performs and is slightly faster when your data already
lives in columns. All arrays must have the same length; missing column
names croak.

=head2 encode_into

    $enc->encode_into(\$buffer, \@rows);

Like L</encode>, but appends the bytes to an existing scalar via reference.
Useful for batching multiple blocks into one HTTP request body without
copying.

=head2 encode_to_handle

    $enc->encode_to_handle($fh, \@rows);

Like L</encode> but writes the bytes directly to a Perl filehandle via
C<PerlIO_write>, skipping a copy. Useful when piping to C<clickhouse-client>
or a network socket.

=head2 for_query

    my $enc = ClickHouse::Encoder->for_query($sql, %opts);

Like L</for_table> but for arbitrary C<select>: runs C<describe
($sql)> to discover the column shape and returns a configured encoder.
Useful when the schema doesn't correspond to a real table (CTEs,
joins, computed columns). Options are the same as L</for_table>; the
caller is responsible for the SQL.

=head2 insert_http

    my $resp = ClickHouse::Encoder->insert_http(
        host => 'localhost', port => 8123, table => 'events',
        columns => \@cols, rows => \@rows,
        compress => 'zstd',   # optional
        scheme   => 'https',  # optional; needs IO::Socket::SSL + Net::SSLeay
        settings => {         # optional per-query CH settings
            max_execution_time => 30,
            max_memory_usage   => '10G',
        },
        dedup_token => $batch_id,  # optional idempotency token
    );
    die "insert failed (status $resp->{status}): $resp->{content}"
        unless $resp->{success};
    # CH response metadata, when present, is also attached:
    my $qid     = $resp->{ch}{'query-id'};
    my $written = $resp->{ch}{summary}{written_rows};

Thin convenience wrapper that builds an encoder, encodes rows, and
POSTs the bytes to C<< http(s)://host:port/?query=insert into $table format native >>.
Pass C<encoder => $enc> instead of C<columns> to reuse one. C<compress>
accepts C<'raw'> (default), C<'zstd'>, or C<'gzip'>. C<scheme =E<gt> 'https'>
enables TLS via L<HTTP::Tiny>'s SSL support (install
L<IO::Socket::SSL> and L<Net::SSLeay>). C<ssl_options> / C<verify_SSL>
pass through to L<HTTP::Tiny>. C<settings> applies per-query CH
settings via URL params. C<dedup_token> stamps the request with an
C<insert_deduplication_token> so an identical retry is rejected
server-side. Returns the L<HTTP::Tiny> response hashref with a
C<ch =E<gt> { query-id, server, format, exception-code, summary,
progress, ... }> slot containing parsed
C<X-ClickHouse-*> response headers; no automatic retries (do HTTP
policy in the caller, or use L</bulk_inserter>).

=head2 for_table

    my $enc = ClickHouse::Encoder->for_table($table, %opts);

Convenience constructor that introspects a table's schema and runs

    describe table $table format tabseparated

C<$table> must be a plain identifier or C<db.table>; each component
matches C<[A-Za-z_][A-Za-z0-9_]*>. Anything else is rejected to avoid
SQL injection through the C<describe table> query.

Options (all optional):

=over 4

=item C<via>

C<'client'> (default) shells out to C<clickhouse-client>. C<'http'> uses
L<HTTP::Tiny> against C<host:port> directly with no external binary
dependency. Recommended on environments without C<clickhouse-client>.

=item C<host>, C<port>, C<database>, C<user>

Connection parameters. Defaults: C<localhost>; C<9000> for
C<<< via => 'client' >>> or C<8123> for C<<< via => 'http' >>>;
C<default>, C<default>.

=item C<password>

For C<client> mode, passed via C<CLICKHOUSE_PASSWORD> env var. For C<http>
mode, sent as the C<X-ClickHouse-Key> header.

=item C<client>

Path to the C<clickhouse-client> executable (only for
C<<< via => 'client' >>>). Default: whatever C<exec> finds on C<$PATH>.

=item C<scheme>, C<timeout>, C<ssl_options>, C<verify_SSL>, C<settings>

For C<<< via => 'http' >>>: the URL scheme (default C<http>; pass
C<https> for TLS), request timeout in seconds (default 10),
optional SSL options / verify_SSL passthrough to L<HTTP::Tiny>,
and a hashref of per-query CH settings. Ignored under
C<<< via => 'client' >>> (the C<clickhouse-client> binary handles
its own connection).

=back

=head2 stream

    $enc->stream(\&iter, \&writer, batch_size => 10_000);

Pulls rows from C<&iter> (a coderef returning the next row, or C<undef> when
done) and emits one Native block per C<batch_size> rows by calling
C<&writer> with the encoded bytes. The iterator loop runs in XS, so the
per-row Perl overhead is bounded.

=head2 streamer

    my $st = $enc->streamer(\&writer, batch_size => 10_000);
    my $st = $enc->streamer(\&writer, batch_size => 10_000,
                            compress => 'lz4');    # XS-level compression
    $st->push_row($row);
    $st->push_row($row);
    ...
    $st->finish;

Returns a C<ClickHouse::Encoder::Streamer> object that buffers rows and
flushes a complete Native block to C<&writer> every C<batch_size> rows.
Call C<finish> to flush any partial last batch, or C<reset> to discard
the buffered rows without flushing (useful for error recovery after an
upstream failure). C<buffered_count> and C<is_empty> let producers
inspect the current backlog. The streamer keeps the encoder alive for
its own lifetime, so dropping the encoder reference after creating the
streamer is safe.

Options:

=over 4

=item C<batch_size =E<gt> N>

Flush every C<N> rows. Default 10_000.

=item C<compress =E<gt> 'lz4' | 'zstd' | 'auto' | 'none'>

When set (and not C<'none'>/C<'raw'>), each emitted batch is wrapped
in CH's compressed-block framing via L</compress_native_block>
before being passed to C<&writer>. Done at the XS level, so no
per-batch Perl-callback overhead beyond the one C<compress_native_block>
call. Pair with L</compressed_writer> only when you want a different
compression scheme on top (e.g. HTTP C<Content-Encoding: gzip>).

=item C<hasher =E<gt> $coderef>

Override the bundled CityHash128 v1.0.2 used by the compression
framing. Useful when integrating with a non-default checksum
implementation; usually omit.

=back

The returned C<ClickHouse::Encoder::Streamer> object exposes:

=over 4

=item C<< $st->push_row(\@row) >>

Append one row. Triggers an auto-flush (one call to C<&writer>)
once the buffer reaches C<batch_size>.

=item C<< $st->finish >>

Flush any partial last batch via C<&writer> and return. Safe to
call multiple times - subsequent calls on an empty buffer are
no-ops, and a fresh C<push_row> after finish reopens the streamer.

=item C<< $st->reset >>

Discard buffered rows without flushing. Useful when an upstream
producer hits an error mid-batch and the in-flight rows should be
dropped rather than emitted with stale data.

=item C<< $st->buffered_count >>

Return the integer count of rows currently buffered (not yet
flushed). Lets producers inspect the backlog before committing.

=item C<< $st->is_empty >>

Return a true value when C<buffered_count == 0>. Convenience for
hot-path checks.

=back

=head2 columns

    my $cols = $enc->columns;
    # [ ['id', 'UInt32'], ['name', 'String'], ... ]

Returns a fresh arrayref of C<[$name, $type]> pairs reflecting the
encoder's schema. The values are copies, not references into the encoder's
internal state.

=head2 validate_rows

    my $errors = $enc->validate_rows(\@rows);
    # [ { row => 7, error => "..." }, ... ]

Trial-encodes each row and collects per-row failures into an arrayref
of C<< { row => $idx, error => $msg } >> hashes (empty arrayref if all
rows are valid). Useful in ETL pipelines that want to log the bad rows
and continue, instead of croaking on the first failure.

The trial encoding does the full encode work and discards the bytes,
so the cost is comparable to a real C<encode> per row. For hot
ingestion paths, prefer letting bad rows croak upstream and only call
C<validate_rows> on suspect batches.

=head2 encode_to_command

    $enc->encode_to_command(\@cmd, \@rows);

Convenience: forks a child running C<@cmd>, opens its stdin as a
write pipe, and streams the encoded bytes into it via
L</encode_to_handle>. Croaks if the fork fails, the exec fails, or the
child exits non-zero; returns nothing on success.

Typical use is piping into C<clickhouse-client>:

    $enc->encode_to_command(
        ['clickhouse-client', '--query', 'insert into events format native'],
        \@rows,
    );

=head2 flatten_nested

    my $cols = ClickHouse::Encoder->flatten_nested(\@cols);

Class method that expands any C<Nested(field T, ...)> entries in a
column list into the flat C<name.field Array(T)> columns ClickHouse
stores them as on the wire. Non-Nested columns pass through unchanged.

    my $cols = ClickHouse::Encoder->flatten_nested([
        ['events', 'Nested(t DateTime, kind String)'],
        ['ts',     'DateTime'],
    ]);
    # => [ ['events.t', 'Array(DateTime)'],
    #      ['events.kind', 'Array(String)'],
    #      ['ts', 'DateTime'] ]
    my $enc = ClickHouse::Encoder->new(columns => $cols);

C<for_table> already returns the flat form because C<describe table>
reports it that way, so this helper is for hand-written schemas that
mirror the user's create table more naturally.

=head2 decode_block

    my $block = ClickHouse::Encoder->decode_block($bytes);

Decode the first Native block in C<$bytes>. Returns a hashref:

    {
        ncols    => $n_columns,
        nrows    => $n_rows,
        columns  => [
            { name => 'id',   type => 'UInt64', values => [...] },
            { name => 'name', type => 'String', values => [...] },
            ...
        ],
        consumed => $bytes_used,
    }

C<consumed> is the number of bytes used. To walk a stream of
concatenated blocks (multi-block C<select format native> response),
prefer L</decode_blocks>. Or pass a starting offset directly:

    my $block = ClickHouse::Encoder->decode_block($bytes, $offset);

The 3-arg form avoids the O(N) C<substr> copy per call that
C<<< substr($bytes, $offset) >>> would entail.

An optional fourth-argument hashref filters which columns to keep:

    my $block = ClickHouse::Encoder->decode_block(
        $bytes, 0, { id => 1, ts => 1 });

Columns whose name isn't in the filter still consume their wire
bytes (so the cursor stays aligned) but their C<values> array is
replaced with N C<undef>s and the column hashref carries a
C<<< skipped => 1 >>> marker. Skips the SV-allocation cost for
unwanted columns; useful on wide C<select *> responses.

XS implementation: walks the Native byte stream using the same type
parser the encoder uses, so symmetric round-trips are guaranteed for
every type C<encode> handles (C<BFloat16>, alphabetical Variant
remapping, C<LowCardinality> dict indirection,
C<SimpleAggregateFunction> passthrough, JSON typed paths, etc.).

C<Decimal128> values come back as C<<< [$lo_uint64, $hi_int64] >>>;
C<Decimal256> as a 4-limb arrayref. Use L</decimal128_str> /
L</decimal256_str> to convert to scaled decimal strings.

=head2 decode_rows

    my $r = ClickHouse::Encoder->decode_rows($bytes);
    my $r = ClickHouse::Encoder->decode_rows($bytes, $offset);

Row-oriented convenience. Returns:

    {
        ncols => $n_columns,
        nrows => $n_rows,
        names => [...],
        types => [...],
        rows  => [[...], [...], ...],
        consumed => $bytes_used,
    }

Calls an XS row-major decoder (C<decode_block_rows>) that walks each
column then immediately distributes its values into the per-row
arrayrefs and frees the column AV. Peak memory holds one column's
AV plus the row AVs (vs both column- and row-major representations
fully alive, which a Perl-side transpose would entail). Throughput
is similar to L</decode_block>; the win is the tighter peak memory
on wide blocks.

=head2 decode_block_rows

    my $r = ClickHouse::Encoder->decode_block_rows($bytes, $offset);

XS row-major decoder; same return shape as L</decode_rows>. Direct
entry point if you want to avoid the L</decode_rows> Perl-side
trampoline.

=head2 decode_blocks

    my $blocks = ClickHouse::Encoder->decode_blocks($bytes);
    ClickHouse::Encoder->decode_blocks($bytes, sub { my $b = shift; ... });

A C<select ... format native> response is a concatenated stream of
blocks (one per granule of C<max_block_size> rows). With no callback,
C<decode_blocks> walks the stream and returns an arrayref of the same
hashref shape as L</decode_block>. With a callback, each block is
passed to the callback as it's decoded and no list is accumulated -
useful for very long selects where the full block list wouldn't fit
comfortably in memory.

Uses the 3-arg form of L</decode_block> (with explicit offset) to
keep total work O(N) regardless of block count. Stops cleanly when
bytes are exhausted; partial trailing bytes croak.

The optional C<keep =E<gt> \%names> hashref forwards a column filter
to L</decode_block> for every block in the stream, matching the
same semantics: present keys are decoded, absent ones still have
their bytes consumed (to keep the cursor aligned) but their values
are not materialized and their column hash carries C<skipped =E<gt> 1>.
Useful for big-fan-out select responses where only a few columns
of a wide row matter.

    ClickHouse::Encoder->decode_blocks($bytes, $cb,
        keep => { id => 1, event => 1 });

=head2 decode_blocks_iter

    my $iter = ClickHouse::Encoder->decode_blocks_iter($bytes);
    while (my $block = $iter->()) { ... }

    my $iter = ClickHouse::Encoder->decode_blocks_iter($bytes,
        keep => { id => 1 });

Returns a coderef that yields one block per call (C<undef> when
exhausted). Same per-block payload as L</decode_block>; useful when
you want pull-style iteration without committing to a callback.
Accepts the same C<keep> filter as L</decode_blocks>.

=head2 decode_stream

    ClickHouse::Encoder->decode_stream($fh, sub { my $block = shift; ... },
                                       chunk_size => 65536);

    ClickHouse::Encoder->decode_stream($fh, $cb,
        keep => { id => 1, event => 1 });

Pull bytes incrementally from a filehandle (or any read-able IO
handle), yielding each complete block to the callback as it
arrives. Uses a sliding buffer; on a truncated decode it reads more
bytes and retries. Memory stays bounded by C<chunk_size> + one
block, so this is the right entry point for select responses too
large to buffer in full. Croaks on partial trailing bytes.

The C<keep> filter is the same one L</decode_block> accepts:
unwanted columns still have their bytes consumed (so the cursor
stays aligned) but their values are not materialized into an SV
array, so peak memory stays bounded by the kept columns.

With C<decompress =E<gt> 1>, C<$fh> is expected to deliver a stream
of compressed-block-framed Native blocks (the format CH's HTTP
C<?compress=1> response uses, or a captured native-TCP Data stream
under compression). C<decode_stream> peels each compressed block
via L</decompress_native_block> before feeding the resulting raw
Native bytes into L</decode_block>.

C<$fh> must support Perl's C<read()> builtin (any plain filehandle
or L<IO::Handle> subclass). Raw socket descriptors that only
support C<sysread> need to be wrapped via L<IO::Socket> or read
into a buffer that is then fed to L</decode_block> directly.

=head2 ping

    ClickHouse::Encoder->ping(host => 'db', port => 8123);
    ClickHouse::Encoder->ping(scheme => 'https', host => 'db', port => 8443);

Liveness check via CH's C</ping> endpoint. Returns C<1> on success;
croaks on connection refused, timeout, or any non-2xx HTTP status.
Accepts the same C<scheme>/C<host>/C<port>/C<timeout>/C<ssl_options>
options as the rest of the HTTP entry points.

=head2 server_version

    my $v = ClickHouse::Encoder->server_version(
        host => 'db', port => 8123);
    if ($v->{major} >= 24) { ... }

Fetches C<select version()> over HTTP. In scalar context returns
C<<< { major, minor, patch, build, raw } >>>; in list context
returns C<($major, $minor, $patch, $build, $raw)>. Useful for
capability gating in user code. Accepts the same
C<scheme>/C<host>/C<port>/C<database>/C<user>/C<password>/C<timeout>/
C<ssl_options>/C<verify_SSL>/C<settings> options as the rest of the
HTTP entry points.

=head2 types

    my @t = ClickHouse::Encoder->types;

Returns the list of supported ClickHouse type names (parametric
types as their syntactic prefix, e.g. C<Decimal>, C<Array>). For
runtime feature detection and tooling that wants to introspect
supported types without parsing POD.

=head2 schema_diff

    my $d = ClickHouse::Encoder->schema_diff(\@cols_a, \@cols_b);
    # $d = {
    #     added   => [[name, type], ...],   # in $b but not $a
    #     removed => [[name, type], ...],   # in $a but not $b
    #     changed => [[name, type_a, type_b], ...],
    # }

Compare two column lists (each an arrayref of C<[$name, $type]>
pairs, the shape L</new> takes). Useful for migration scripts and
detecting schema drift between source and destination in CH-to-CH
replication pipelines.

=head2 format_create_table

    my $sql = ClickHouse::Encoder->format_create_table(
        table        => 'events',
        columns      => [['id','Int32'], ['msg','String']],
        engine       => 'MergeTree',           # default
        order_by     => '(id)',
        partition_by => 'toYYYYMM(ts)',        # optional
        primary_key  => '(id)',                # optional
        sample_by    => 'id',                  # optional
        ttl          => 'event_date + INTERVAL 90 DAY',  # optional
        settings     => 'index_granularity=8192', # optional
    );

Emits a C<create table> statement string from a column list of the
same shape L</new> takes. The C<table> name is validated by the
same regex L</for_table> / L</insert_http> use, and column names
are backtick-quoted with embedded backticks escaped. The
C<engine> / C<partition_by> / C<primary_key> / C<order_by> /
C<sample_by> / C<ttl> / C<settings> opts are inserted verbatim -
the caller is responsible for SQL correctness there. Clauses are
emitted in CH's canonical C<show create table> order, so the output
round-trips through L</parse_create_table> without reordering.

A column entry may be C<[name, type]> or C<[name, type, \%col]>,
where C<%col> carries per-column modifiers rendered in CH's own
order: one of C<default> / C<materialized> / C<alias> (an
expression; passing more than one croaks), then C<codec>, then
C<ttl>, then C<comment>. The C<comment> is quoted as a string
literal (embedded single quotes escaped); every other value is
inserted verbatim.

    my $sql = ClickHouse::Encoder->format_create_table(
        table   => 'events',
        columns => [
            ['id',   'UInt64'],
            ['ts',   'DateTime', { codec => 'DoubleDelta, LZ4' }],
            ['kind', 'String',   { default => "'unknown'",
                                   comment => 'event kind' }],
        ],
        engine => 'MergeTree', order_by => '(id, ts)',
        ttl    => 'ts + INTERVAL 30 DAY',
    );

Pair with L</schema_diff> + L</apply_schema_diff> for end-to-end
schema migration tooling.

=head2 parse_create_table

    my $info = ClickHouse::Encoder->parse_create_table($show_create_sql);
    # $info = {
    #   database => 'analytics', table => 'events',
    #   columns  => [['id','UInt64'], ['name','String'], ...],
    #   engine   => 'MergeTree', order_by => '(id, ts)',
    #   partition_by => 'toYYYYMM(ts)', primary_key => 'id',
    #   sample_by => 'id', ttl => 'ts + INTERVAL 90 DAY',
    #   settings => 'index_granularity = 8192',
    # }
    # Clause keys are present only when the DDL has that clause.

Parses the output of C<show create table> (or any C<create table>
DDL) into a structured hashref. C<columns> is in the same
C<[name, type]> shape L</schema_diff> and L</format_create_table>
consume, so a round trip - fetch DDL, parse, diff against a desired
shape, emit C<ALTER>s - is one call each. Per-column
C<DEFAULT> / C<CODEC> / C<TTL> / C<COMMENT> modifiers are stripped
from the reported type (the bare type is what C<describe> reports).
Nested-comma types (C<Decimal(18, 4)>, named C<Tuple>, C<Map>) and
backtick-quoted identifiers are handled. C<database> is C<undef>
when the name is not schema-qualified. Croaks if no C<create table>
header or column block is found.

Trailing clauses (C<ENGINE>, C<partition by>, C<TTL>, ...) are
delimited by the next clause keyword: a clause expression that
itself embeds a standalone clause keyword (rare - e.g. a C<TTL>
expression containing the bare word C<SETTINGS>) would be truncated
there. The column list is parsed precisely; clause values are
best-effort.

=head2 apply_schema_diff

    my $diff  = ClickHouse::Encoder->schema_diff(\@before, \@after);
    my $stmts = ClickHouse::Encoder->apply_schema_diff(
        $diff, table => 'events');
    # $stmts = [ 'alter table `events` drop column `old_col`',
    #            'alter table `events` modify column `x` UInt32',
    #            'alter table `events` add column `new_col` Int64' ]

Translates a L</schema_diff> hashref into a list of C<alter table>
statements. Returns an arrayref of SQL strings; the caller decides
whether to apply them transactionally or one at a time. Ordering is
deterministic: drops first, then modifies, then adds.

=head2 for_native_bytes

    my $enc = ClickHouse::Encoder->for_native_bytes($captured_bytes);

Inspect a captured Native block and return a fresh encoder
configured for that exact column shape. Zero-row blocks work fine
(the column headers are still on the wire); the typical use case
is round-tripping captured payloads through a transform / filter
step where you need an encoder matching the input's schema but
don't have access to the source server.

=head2 encode_row_binary

    my $body = $enc->encode_row_binary(\@rows);
    # POST as: insert into t format RowBinary

Encode rows into ClickHouse's row-major C<RowBinary> format (the
request body for C<insert ... format RowBinary>). Native is the
preferred format and is what the rest of this module uses;
C<RowBinary> is offered for interoperability with producers and
pipelines that speak it. Call on an encoder instance - its column
types drive serialisation.

Supported column types: every scalar type
(C<Int*>/C<UInt*>/C<Float*>/C<Bool>/C<Date*>/C<DateTime*>/
C<Decimal*>/C<UUID>/C<IPv4>/C<IPv6>/C<Enum*>), C<String>,
C<FixedString(N)>, C<Nullable(...)> of any of those, C<Array(...)>
nesting, and C<LowCardinality(...)> (encoded as its inner type, as
RowBinary represents it). C<Map>, C<Tuple>, C<Variant>, C<JSON>,
C<Dynamic>, Geo and C<Nested> columns croak - their Native and
RowBinary framings differ. Use Native (L</encode>) for those.

=head2 decode_row_binary

    my $rows = $enc->decode_row_binary($bytes);

Decode a C<RowBinary> byte string into an arrayref of row
arrayrefs. Call on an encoder instance whose column types match the
producer (RowBinary carries no schema, so the types must be known
out of band). The supported type surface and per-type value
semantics are identical to L</encode_row_binary> and to the Native
decoder - C<decode_row_binary> yields the same Perl values
L</decode_block> would for the same data.

=head2 coerce_datetimes

    my $blk = ClickHouse::Encoder->decode_block($bytes);
    ClickHouse::Encoder->coerce_datetimes($blk);             # ISO strings
    ClickHouse::Encoder->coerce_datetimes($blk, as => 'datetime');  # Time::Moment

Post-process a decoded block: rewrite every C<Date> / C<Date32> /
C<DateTime> / C<DateTime(tz)> / C<DateTime64(p)> column's values
from raw epoch integers into either ISO 8601 strings (the default;
UTC with a C<Z> suffix) or L<Time::Moment> instances
(C<as =E<gt> 'datetime'>). The block is mutated in place and also
returned, so the call can be chained.

C<Nullable()>-wrapped time columns are handled too; C<undef>
values pass through unchanged. Non-time columns are untouched.
C<DateTime64(p)> precision is honored - the fractional part is
emitted as exactly C<p> digits in ISO form, or as nanoseconds
widened from C<p> ticks in C<Time::Moment> form.

This is a separate post-decode step (rather than an option on
L</decode_block>) so the cost is only paid when the caller wants
formatted values. Raw integer epochs are still cheaper to compare,
filter, or pass back into a re-encode.

=head2 parse_wkt

    my $point = ClickHouse::Encoder->parse_wkt('POINT(1.5 2.5)');
    my $poly  = ClickHouse::Encoder->parse_wkt(
        'POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))');
    # round-trip into a CH Geo column:
    my $enc = ClickHouse::Encoder->new(columns => [
        ['p', 'Point'], ['poly', 'Polygon']]);
    $enc->encode([[ $point, $poly ]]);

Parse a Well-Known-Text geometry string into the nested-arrayref
shape that the Geo column encoders accept. Supports C<POINT>,
C<LINESTRING>, C<MULTILINESTRING>, C<POLYGON>, and C<MULTIPOLYGON>.
The CH C<Ring> type has no WKT name; feed a C<LINESTRING> result
into a Ring column directly. Geometry names are case-insensitive
and surrounding whitespace is tolerated. Malformed input croaks
with a message identifying the offending geometry.

=head2 estimate_size

    my $bytes = $enc->estimate_size(\@rows);
    my $bytes = $enc->estimate_size($n_rows,
                                    avg_string_size => 64);

Coarse byte-size estimate for an encoded block, parameterized on row
count (an integer or arrayref-of-rows; only the count is used).
Returns an order-of-magnitude figure for batch-split decisions
("should I split this into two POSTs?") without paying the encode
cost. Fixed-width types are byte-exact; variable types
(C<String>, C<Array>, etc.) use a configurable 16-byte average
heuristic. For byte-exact size, call C<length($enc-E<gt>encode(...))>.

=head2 select_blocks

    ClickHouse::Encoder->select_blocks(
        'select id, event, ts from events where date = today()',
        host     => 'db.example', port => 8123,
        database => 'default',    user => 'default',
        on_block => sub { my $block = shift; ... },
        keep     => { id => 1, event => 1 },  # optional projection
    );

Streaming counterpart to L</insert_http>: POSTs C<$sql> to the
ClickHouse HTTP endpoint with C<default_format=Native>, feeds the
response chunks into a sliding buffer, and invokes C<on_block> for
every complete L</decode_block>-shaped block as it arrives. Memory
stays bounded by one HTTP::Tiny chunk plus one block; this is the
right entry point for selects that return more than fits in
process memory.

C<$sql> must NOT end with a C<format ...> clause - C<select_blocks>
appends C<format Native> at the URL level and croaks when the SQL
trails with a different format pin. A C<FORMAT> token inside the
query body (for example a column literal) is fine.

The optional C<keep =E<gt> \%names> hashref forwards a column
filter to L</decode_block>: skipped columns still have their bytes
consumed (so the cursor stays aligned) but their values are not
materialized into SVs. Useful when you only need a few of many
select-list columns.

With C<decompress =E<gt> 1> the URL is augmented with
C<?compress=1> so ClickHouse wraps each response Native block in
its compressed-block framing (16-byte CityHash128 + 9-byte header
+ LZ4 payload). The HTTP body is then a stream of compressed blocks
which C<select_blocks> peels and decompresses block-by-block via
L</decompress_native_block> before feeding the result to
L</decode_block>. Memory stays bounded by one HTTP chunk plus one
compressed block plus one decompressed block.

Recognised options (besides C<on_block> / C<keep> /
C<decompress>): C<scheme>, C<host>, C<port>, C<database>, C<user>,
C<password>, C<timeout>, C<ssl_options>, C<verify_SSL>, and
C<settings> (per-query CH settings hashref, useful for
C<max_execution_time> and similar). C<dedup_token> is meaningful
only on insert and is ignored if passed here.

=head2 bulk_inserter

    my $bi = ClickHouse::Encoder->bulk_inserter(
        host => 'db.example', port => 8123, table => 'events',
        columns => \@cols, batch_size => 5000, compress => 'zstd',
        retries => 3);
    $bi->push([$row]) for @rows;
    $bi->finish;

Holds an L<HTTP::Tiny> instance with keep-alive across batches,
accumulates rows, auto-flushes at C<batch_size>, retries transient
HTTP failures (5xx and 599 network errors) with exponential backoff
and jitter. 4xx errors die immediately. Options:

=over 4

=item C<host>, C<port>, C<database>, C<user>, C<password>, C<scheme>, C<timeout>

Same as L</for_table>; passed to L<HTTP::Tiny>.

=item C<table>

Required; same identifier rule as L</for_table>.

=item C<encoder> or C<columns>

Pass either an existing encoder or a column list (used to build one).

=item C<batch_size>

Auto-flush threshold (default 10_000).

=item C<retries>

Max retries on transient failure (default 3). Set to 0 to disable.

=item C<retry_wait>

Base backoff in seconds (default 0.5). Waits grow exponentially -
the window for attempt I<n> is C<retry_wait * 2 ** n> - with equal
jitter (a random point in the upper half of the window), so
concurrent inserters retrying the same failed server do not
resynchronise into a thundering herd.

=item C<retry_max_wait>

Upper bound in seconds on the backoff window (default 30), capping
the exponential growth from C<retry_wait>.

=item C<compress>

C<'raw'> (default), C<'zstd'>, or C<'gzip'>. Sets the
C<Content-Encoding> header accordingly.

=item C<scheme>, C<ssl_options>, C<verify_SSL>

C<scheme =E<gt> 'https'> enables TLS via L<HTTP::Tiny> (install
L<IO::Socket::SSL> and L<Net::SSLeay>). C<ssl_options> and
C<verify_SSL> pass through to L<HTTP::Tiny>.

=item C<settings>

Hashref of per-query CH settings (C<max_execution_time>,
C<max_memory_usage>, ...) appended to every flush as URL params.

=item C<dedup_token>

Stamps every POST with C<insert_deduplication_token>. Identical
retries are rejected server-side, making the inserter
transactionally idempotent.

=back

Methods on the returned object:

=over 4

=item C<<< $bi->push($row) >>>

Append a single row. Auto-flushes if buffer crosses C<batch_size>.

=item C<<< $bi->push_many(\@rows) >>>

Append many rows in one call.

=item C<<< $bi->flush >>>

Flush whatever is in the buffer (idempotent: no-op when empty).

=item C<<< $bi->finish >>>

Flush and return C<<< { rows => $sent_total, batches => $batches } >>>.

=item C<<< $bi->buffered_count >>> / C<<< $bi->sent_rows >>> / C<<< $bi->sent_batches >>>

Instrumentation accessors.

=item C<<< $bi->summary >>>

Hashref of cumulative C<X-ClickHouse-Summary> stats rolled up across
batches (C<written_rows>, C<written_bytes>, C<elapsed_ns>, ...).

=item C<<< $bi->last_response >>>

The L<HTTP::Tiny> response hashref from the most recent flush, with
the parsed C<ch =E<gt> { query-id, server, format, exception-code,
summary, progress, ... }>
slot attached (whichever C<X-ClickHouse-*> headers the server sent).
C<undef> until the first flush succeeds.

=back

=head2 decimal128_str

    my $s = ClickHouse::Encoder->decimal128_str($lo, $hi, $scale);

Convert a decoded C<Decimal128> low/high uint64 pair (as returned
by L</decode_block>) into a signed decimal string with the given
fractional scale. Uses L<Math::BigInt> for the 128-bit arithmetic.

=head2 decimal256_str

    my $s = ClickHouse::Encoder->decimal256_str(\@limbs, $scale);

Convert a decoded C<Decimal256> 4-limb arrayref (low-to-high
uint64s, as returned by L</decode_block>) into a signed decimal
string with the given fractional scale. Uses L<Math::BigInt> for
the 256-bit arithmetic.

=head2 compressed_writer

    my $w = ClickHouse::Encoder->compressed_writer('zstd', \&raw_writer);
    my $st = $enc->streamer($w, batch_size => 1000);

Class method that wraps a writer coderef so each emitted block is
compressed before being forwarded. Modes: C<'zstd'> (requires
L<Compress::Zstd>), C<'gzip'> (uses core L<IO::Compress::Gzip>),
C<'raw'> / C<undef> (pass-through). Compose with L</stream> or
L</streamer>; the wrapper handles one block at a time so memory stays
proportional to a single batch.

=head2 compress_native_block

    my $framed = ClickHouse::Encoder->compress_native_block(
        $native_bytes,
        mode   => 'lz4',  # 'lz4' | 'zstd' | 'auto' | 'none'
        # hasher => \&my_cityhash128,   # optional; default = bundled
    );

Wraps an encoded Native block in ClickHouse's CompressedReadBuffer
framing: a 16-byte checksum, then a 9-byte header (1-byte method
tag + LE UInt32 compressed_size + LE UInt32 uncompressed_size),
then the LZ4 (tag C<0x82>), ZSTD (tag C<0x90>), or uncompressed
(tag C<0x02>) payload. This is the framing used by the native TCP
protocol when compression is negotiated and by Native-over-HTTP
with C<&compress=1> / C<&decompress=1>.

Modes:

=over 4

=item C<'lz4'>

LZ4-compressed via L<Compress::LZ4>'s raw form (no length prefix).

=item C<'zstd'>

ZSTD-compressed via L<Compress::Zstd>.

=item C<'auto'>

Try LZ4 first; if the result is C<E<gt>=> the input, fall back to
C<'none'>. Mirrors CH's own C<CompressedWriteBuffer> behavior for
incompressible payloads.

=item C<'none'>

No compression but still wrapped in the framing (method tag C<0x02>).
Useful when the wire context requires compressed-block framing but
the payload doesn't benefit from compression.

=back

The checksum is CityHash128 in the "cityhash102" variant
(ClickHouse's namespace fork of Google CityHash v1.0.2). This
module bundles a port of that algorithm in F<cityhash.c>, exposed
as the XSUB C<_cityhash128>; both C<compress_native_block> and
L</decompress_native_block> default to it. Pass an explicit
C<hasher =E<gt> $coderef> only if you want to plug in a different
implementation.

C<Compress::LZ4> is required for C<'lz4'> / C<'auto'> mode;
C<Compress::Zstd> for C<'zstd'>. Both are listed as runtime
C<recommends>.

=head2 decompress_native_block

    my ($plain, $consumed) = ClickHouse::Encoder->decompress_native_block(
        $framed);                          # default hasher = bundled
    my $plain = ClickHouse::Encoder->decompress_native_block(
        $framed, hasher => undef);         # skip checksum verification
    my ($plain, $n) = ClickHouse::Encoder->decompress_native_block(
        $stream, offset => $cursor);       # walk a multi-block stream

Inverse of L</compress_native_block>: verifies the checksum (unless
C<hasher =E<gt> undef>), unpacks the payload by method tag, and
returns the raw Native bytes. In list context also returns the
number of bytes consumed from C<$bytes> (16 + 9 + payload length),
so the caller can advance an offset cursor through a stream of
back-to-back compressed blocks.

=head1 TYPES

=head2 Supported

=over 4

=item *

Integers: C<Int8>, C<Int16>, C<Int32>, C<Int64>, C<UInt8>, C<UInt16>,
C<UInt32>, C<UInt64>.

=item *

Floats: C<Float32>, C<Float64>, C<BFloat16> (CH 24.x; 2-byte truncated
Float32). C<Inf>, C<-Inf>, and C<NaN> are preserved.

=item *

Strings: C<String> (length-prefixed bytes), C<FixedString(N)> (N bytes,
null-padded). Both pass the SV's bytes through unchanged: a UTF-8 string
encodes its UTF-8 bytes, a binary blob encodes its bytes, and truncation
is by byte not codepoint.

=item *

Dates: C<Date>, C<Date32>, C<DateTime>, C<DateTime('tz')> (timezone is part
of the schema, not the value), C<DateTime64(P)> with C<P> in 0..9.

=item *

Decimals: C<Decimal32(S)> (S in 0..9), C<Decimal64(S)> (0..18),
C<Decimal128(S)> (0..38), C<Decimal256(S)> (0..76), and
C<Decimal(P, S)> with C<P> in 1..38 (auto-routed to 32/64/128).

=item *

Enums: C<Enum8('a' = 1, ...)>, C<Enum16(...)>.

=item *

C<Bool> / C<Boolean> (1 byte; truthy/falsy in Perl sense).

=item *

C<UUID> (16 bytes; accept either the standard
C<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx> string or 16 raw bytes).

=item *

C<IPv4> (UInt32 LE; accept dotted-quad string or integer),
C<IPv6> (16 bytes network-order; accept colon-hex string or 16 raw bytes).

=item *

C<Map(K, V)> (wire-equivalent to C<Array(Tuple(K, V))>; accept either a
hashref or an arrayref of pairs).

=item *

C<Variant(T1, T2, ...)> (CH 24.1+; tagged union). Each row is either
C<undef> (null) or C<[$variant_idx, $value]>, where C<$variant_idx> is
the 0-based position in the declared C<Variant(...)> type list (so
C<Variant(String, UInt32)> uses 0 for String and 1 for UInt32). Up to 254
variants. ClickHouse stores Variant arms alphabetically by type name on
the wire; the encoder remaps your declared index transparently, so you
always use declaration order in your code. C<describe table> returns the
arms already alphabetized, and C<for_table> uses that form, so indices
match either way.

=item *

C<LowCardinality(String)>, C<LowCardinality(FixedString(N))>,
C<LowCardinality(Nullable(String))>, C<LowCardinality(Nullable(FixedString(N)))>.

=item *

Geo: C<Point>, C<Ring>, C<LineString>, C<MultiLineString>, C<Polygon>,
C<MultiPolygon> (aliases over C<Tuple>/C<Array>). L</parse_wkt> turns
a Well-Known-Text string into the nested-arrayref input these
columns expect.

=item *

Composites: C<Array(T)>, C<Tuple(T1, T2, ...)>, C<Nullable(T)>. Arbitrary
nesting; C<Nullable(Nullable(T))> is rejected, matching ClickHouse. Named
tuple elements (C<Tuple(a Int32, b String)>) are accepted; the wire
format itself ignores names, but for a named tuple the encoder will
also accept rows as hashrefs (C<<< { a => 1, b => "x" } >>>) in addition
to arrayrefs (C<[1, "x"]>). Missing keys in a hashref encode as the
type's null placeholder.

=item *

C<SimpleAggregateFunction(func, T)>: parsed as plain C<T>; the
aggregation function name only affects how readers consume the column,
not the wire-level binary format. Full C<AggregateFunction> (with
function-specific binary state) is not supported; use
C<SimpleAggregateFunction> where the inner type matches the on-the-wire
representation.

=item *

C<JSON> / C<Object('json')> (the stable CH 24.8+ JSON type). Each row
is a hashref of leaf values; nested hashrefs are auto-flattened into
dotted-path subcolumns matching CH's internal storage (so
C<<< { user => { name => "alice" } } >>> stores under the C<user.name>
path on the wire and round-trips back as the same nested structure
on decode). Leaf value typing is inferred per-path from Perl SV flags:

=over 4

=item *

Numeric SV with the integer flag set but not the float flag
(C<SvIOK && !SvNOK>) -> C<Int64>.

=item *

Numeric SV with the float flag set (C<SvNOK>): non-integer value ->
C<Float64>; a NV that happens to equal an integer (e.g. C<1.0>)
collapses to C<Int64> on the wire, mirroring CH's own C<JSONEachRow>
inference. Round-trip then decodes back as an integer; to keep an
integer-valued float as C<Float64> use a dedicated C<Float64> column
or a C<<< Variant(Float64, ...) >>>. C<NaN> and C<Inf> stay C<Float64>.

=item *

Blessed scalarref into C<JSON::PP::Boolean>, C<JSON::XS::Boolean>,
C<Types::Serialiser::Boolean>, C<Cpanel::JSON::XS::Boolean>, or
C<boolean> -> C<Bool>. Perl 5.36+ native booleans (C<SvIsBOOL>) also work.

=item *

Anything else stringy -> C<String>.

=item *

C<undef> -> null discriminator for that path in that row.

=back

A path's per-row types may differ; ClickHouse's Dynamic sub-column
representation handles the union. Multiple rows of the same path
sharing different types are encoded as a Variant. Each variant kind
is one of: C<Bool>, C<Float64>, C<Int64>, C<String>, or an
C<Array(...)> of those (homogeneous element type per array). Mixed
or nested arrays are rejected with a clear message.

The C<JSON(name Type, name Type, ...)> form pins specific paths to
concrete inner types ("typed paths"). Those paths skip the
Dynamic+Variant wrapping and emit as regular columns, which is
cheaper on the wire and lets you query them as concrete types
server-side without C<toInt64()> / C<toString()> coercion. Path
names may be dotted (e.g. C<JSON(user.id UInt64)>), the type list
is comma-separated, and typed paths are independent of the dynamic
paths (extra keys still go through Variant). Missing typed keys
encode the inner type's default (0 for numerics, empty for String /
Array / Map, null for Nullable). Inner types whose ClickHouse
serialization includes a wire prefix (C<Variant>,
C<LowCardinality>, C<JSON>, C<Dynamic>) are rejected at encoder
construction.

=item *

C<Dynamic> as a standalone column type: same wire format as one
JSON path's Dynamic sub-column without the Object wrapper. Each row
is a scalar leaf (C<Bool> / C<Float64> / C<Int64> / C<String>), an
C<Array(...)> of those, or C<undef> (null). Hashrefs aren't accepted
here - use a JSON column for object-shaped values.

=back

=head2 Not currently supported

C<LowCardinality(T)> for non-string T, C<AggregateFunction> (per-function
binary state).

Heterogeneous arrays as JSON leaves (e.g. C<<< [1, "two"] >>>); only
homogeneous arrays of C<Bool> / C<Float64> / C<Int64> / C<String>
are supported. Arrays-of-objects (C<<< [{...}, {...}] >>>) and
nested arrays (C<<< [[1,2],[3,4]] >>>) are likewise rejected. Future
work.

C<Nested(...)> at the encoder level. ClickHouse splits a C<Nested> column
on the wire into flat C<name.field> columns of type C<Array(T)>; this
encoder doesn't perform that expansion. Use the flat form directly:

    columns => [
        ['events.time', 'Array(DateTime)'],
        ['events.type', 'Array(String)'],
    ],

C<for_table()> introspects this form correctly because C<describe table>
returns the flat columns.

=head2 Value coercion

=over 4

=item *

Numeric types go through C<SvIV> / C<SvUV> / C<SvNV>. Negative inputs to
unsigned types are bit-cast (standard Perl behaviour).

=item *

C<Date> / C<Date32>: integer (or integer-valued string) is interpreted as
days since the epoch; a C<YYYY-MM-DD> string is parsed. Pass DateTime /
Time::Piece / Time::Moment objects as C<< $dt->epoch / 86400 >> -- the
encoder doesn't dispatch through C<< ->epoch >> itself.

=item *

C<DateTime>: integer is Unix seconds; a C<YYYY-MM-DD HH:MM:SS> string is
parsed. ISO 8601 forms are accepted: the C<T> separator, plus an optional
trailing timezone marker (C<Z>, C<+HH:MM>, C<-HH:MM>, C<+HHMM>, C<+HH>,
C<-HH>) is applied to convert to UTC. Pass date-objects via their
C<< ->epoch >>.

=item *

C<DateTime64(P)>: integer is in scaled units (i.e. ticks of
C<10^-P> seconds); a float is in seconds and scaled to ticks; a
C<YYYY-MM-DD HH:MM:SS.fff> string is parsed. For sub-second-aware
objects pass C<< $dt->hires_epoch >> (or C<< ->epoch >> if the object
is integer-only).

=item *

C<Decimal*>: a number goes through C<double> (lossy past 2^53); a
B<string> matching C<[+-]?digits[.digits]?> is parsed digit-by-digit and
scaled exactly. B<If precision matters, pass strings.>

=item *

C<Enum8> / C<Enum16>: accept either the declared name or its integer
value; mixing the two within a column is fine.

=item *

C<Nullable(T)>: C<undef> writes a null-bitmap entry plus a type-shaped
placeholder (zero scalar, empty array, or a recursive zero tuple).

=back

=head1 EXAMPLES

The F<eg/> directory ships runnable scripts:

=over 4

=item F<eg/insert_http.pl>

End-to-end insert over HTTP via L<HTTP::Tiny>. The shortest path to "insert
real data into a real ClickHouse".

=item F<eg/insert_streaming.pl>

Reuse one encoder across many batches, piping each batch to
C<clickhouse-client>. Demonstrates the intended one-encoder-many-batches
pattern.

=item F<eg/for_table.pl>

Schema discovery via C<for_table>.

=item F<eg/from_csv.pl>

Read a CSV with L<Text::CSV_XS>, map columns to a ClickHouse schema, and
insert via HTTP.

=item F<eg/insert_clickhouse_local.pl>

Server-less ETL: encode rows, pipe Native bytes into C<clickhouse-local>,
have it write a Parquet (or ORC, etc.) file.

=item F<eg/etl_dbi.pl>

Read rows from a source database via L<DBI>, encode to Native, insert into
ClickHouse via HTTP. Reuses one encoder across all fetched batches.

=item F<eg/insert_compressed.pl>

insert with on-the-wire compression (zstd via L<Compress::Zstd>, falling
back to gzip via core L<IO::Compress::Gzip>). Sets C<Content-Encoding>
so ClickHouse decompresses transparently.

=item F<eg/insert_async_ev.pl>

Non-blocking concurrent inserts using L<EV>'s event loop with raw HTTP
sockets, paired with this encoder's L</streamer>. Demonstrates the
"many in-flight inserts without blocking on each round-trip" pattern.

=item F<eg/insert_with_lowcardinality.pl>

Measures the wire-size reduction (~50% on event/log data) and encoding
throughput of C<LowCardinality(String)> versus plain C<String> for the
typical case where a column has few distinct values that repeat across
many rows.

=item F<eg/json_lines_ingest.pl>

Reads NDJSON from STDIN or a file, maps each object's fields onto a
ClickHouse table's columns (discovered via C<for_table>), and inserts
batched blocks over HTTP.

=item F<eg/streaming_aggregate.pl>

Pre-aggregates an event stream in Perl (per minute, per key) and
flushes rolled-up counters to a C<SummingMergeTree> on a wall-clock
timer. The classic pattern when the firehose is too high-cardinality
to store as raw rows.

=item F<eg/postgres_to_clickhouse.pl>

Replicates a PostgreSQL table to ClickHouse using L<DBD::Pg> on the
source side and this encoder's streamer on the destination side.
Memory is bounded by the batch size, so it scales to hundreds of
millions of rows.

=item F<eg/clickhouse_replication.pl>

Replicates one ClickHouse table to another (potentially on a different
server) by streaming Native bytes end-to-end via a temp-file spool.

=item F<eg/parallel_loader.pl>

Forks N worker processes, each ingesting one slice of the input.
Workers share nothing; each opens its own HTTP connection. Scales
network-bound ingestion linearly with worker count.

=item F<eg/redis_to_clickhouse.pl>

Drains a Redis stream (XREADGROUP) or list (BRPOP) into a ClickHouse
table, with idle-flush so the destination doesn't see arbitrarily
delayed batches when the source is quiet.

=item F<eg/syslog_ingest.pl>

Reads RFC 5424 syslog lines from STDIN, parses lossily (any
unparseable line still goes through with the raw text in C<msg>),
and inserts into a fixed schema.

=item F<eg/json_streaming.pl>

NDJSON from STDIN into a C<JSON> column via the encoder's streaming
mode; one HTTP request per batch instead of one per line.

=item F<eg/json_query.pl>

C<select ... format Native> over HTTP and walks the returned blocks
via L</decode_blocks>, demonstrating the symmetric decode path for
JSON columns.

=item F<eg/json_aggregate.pl>

Sketches an aggregation pipeline that bins JSON events by path and
emits the aggregates as a second insert.

=item F<eg/migrate_table.pl>

Copies one CH table into another (possibly on a different host) by
discovering the source schema via L</for_table> and streaming Native
blocks through.

=item F<eg/native_to_jsonl.pl>

Reads a Native byte stream from STDIN and prints each row as NDJSON
on STDOUT; the dual of F<json_lines_ingest.pl>.

=item F<eg/replay.pl>

Replays a captured Native byte stream against a table, useful for
post-hoc reproduction of an ingest bug from a saved request body.

=item F<eg/select_blocks_streaming.pl>

Streaming select counterpart to F<insert_streaming.pl>: uses
L</select_blocks> to walk a select response block-by-block, with
optional column projection via C<--keep>.

=item F<eg/json_path_projection.pl>

Demo of C<keep =E<gt> {...}> projection on top of L</select_blocks>:
decodes only the requested columns and prints one row per line.

=item F<eg/csv_export.pl>

select to CSV: counterpart to F<from_csv.pl>. Drives a CSV writer
from a streaming select, emitting the header row from the first
block's column names.

=item F<eg/migrate_with_transform.pl>

CH-to-CH migration with a row-level transform between read and
write. Discovers source schema via L</for_table>, streams the rows
via L</select_blocks>, applies a user-supplied transform coderef,
and forwards survivors through L</bulk_inserter>.

=item F<eg/replay_pcap.pl>

Replay a captured Native byte stream (e.g. saved from
C<curl --output> of a C<select ... format native> response) and
print a block-by-block summary. Off-line debugging tool.

=item F<eg/tcp_compressed_pipeline.pl>

End-to-end TCP insert pipeline that negotiates compression in
C<pack_query>, then wraps every C<pack_data> / C<pack_data_end>
in CH's compressed-block framing. Showcases the matched-pair
convention against a real ClickHouse server (protocol revision
E<lt>= 54474; see L<ClickHouse::Encoder::TCP/CAVEATS>).

=item F<eg/rowbinary_insert.pl>

insert using the C<RowBinary> format via L</encode_row_binary>,
with a local L</decode_row_binary> round-trip check. For interop
with pipelines that speak RowBinary rather than Native.

=item F<eg/async_insert.pl>

Server-side async insert - C<async_insert=1> (and optionally
C<wait_for_async_insert>) passed through the C<settings> option,
so the server buffers and background-flushes the batch.

=item F<eg/geo_from_wkt.pl>

Ingest geometry given as Well-Known-Text into C<Point> / C<Polygon>
columns using L</parse_wkt> to convert each WKT string.

=item F<eg/insert_with_settings.pl>

insert with per-query CH C<settings> and an C<insert_deduplication_token>,
showing how an identical retry under the same token is deduplicated
server-side.

=item F<eg/ping_healthcheck.pl>

A wait-for-server readiness gate built on L</ping> - retry until the
C</ping> endpoint answers, then proceed.

=item F<eg/observability.pl>

Reads server-side stats from an insert pipeline: per-batch
C<< $bi->last_response->{ch} >> detail plus the cumulative
C<< $bi->summary >> rollup of C<X-ClickHouse-Summary> counters.

=item F<eg/schema_migrate.pl>

Fetches C<show create table>, parses it with L</parse_create_table>,
diffs the columns against a desired schema, and emits the
C<alter table> migration via L</apply_schema_diff>.

=back

For a working reference of the ClickHouse Native binary format that this
module emits, see F<doc/wire-format.md>.

=head1 PERFORMANCE

The encoder is written so that the dominant cost on most workloads is the
data-generation Perl code, not the encoding step. Some indicative numbers
from F<bench/local_insert_benchmark.pl> (500_000 rows, 5 columns including
C<Array(String)>, in-process via C<clickhouse-local>):

    Native (this module)    encode 0.29s + ingest 0.13s = 0.42s end-to-end
    TabSeparated (Perl)     encode 0.79s + ingest 0.11s = 0.90s end-to-end
    -> Native ~2x faster end-to-end, payload ~18% smaller

For wide tables with many string columns the gap widens (the XS encoder
pulls further ahead of plain-Perl TSV serialization). See F<bench/> for
reproducible scripts and additional scenarios.

=head1 CAVEATS

=over 4

=item *

A 64-bit Perl is required (C<< $Config{ivsize} >= 8 >>). On a 32-bit perl
F<Makefile.PL> exits with C<OS unsupported> (CPAN Testers reports NA, not
FAIL) because C<Int64> / C<UInt64> would otherwise silently truncate.

=item *

Output is little-endian; this matches every supported ClickHouse server
build. The encoder relies on the host's native float byte order matching
its native integer byte order, which holds on every IEEE 754 platform in
practice.

=item *

C<encode> builds the whole block in memory. For very large batches you
typically want to chunk into multiple C<encode> calls and send each block
sequentially.

=item *

L</compress_native_block> and L</decompress_native_block> bundle a
port of CityHash128 v1.0.2 (the "cityhash102" variant ClickHouse uses
internally) in F<cityhash.c>. Wire compatibility with a real CH
server is exercised by F<t/live.t> against an installed server.

=back

=head1 SEE ALSO

L<ClickHouse::Encoder::TCP> - pack/unpack a subset of ClickHouse's
native TCP protocol packets, for driving insert pipelines directly
over port 9000 (transport is the caller's choice). Targets protocol
revision 54429.

L<EV::ClickHouse> - async ClickHouse client supporting both HTTP and the
native TCP protocol with the full handshake (including chunking
negotiation that this module skips).

L<ClickHouse Native format|https://clickhouse.com/docs/en/interfaces/formats#native>,
L<ClickHouse HTTP interface|https://clickhouse.com/docs/en/interfaces/http>.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
