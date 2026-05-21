use Test2::V0;
use Atomic::Pipe;
use IO::Handle;

plan skip_all => 'Compress::Zstd not installed'
    unless eval { require Compress::Zstd; 1 };

# Older Compress::Zstd releases ship without the Context/Dictionary
# submodules used by the dict-aware path. Probe once and skip those
# subtests if any are missing so the rest of the suite still runs.
my $HAVE_DICT = eval {
    require Compress::Zstd::CompressionContext;
    require Compress::Zstd::DecompressionContext;
    require Compress::Zstd::CompressionDictionary;
    require Compress::Zstd::DecompressionDictionary;
    1;
};

subtest accessors_default => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    is($r->compression,                  undef, 'compression undef by default');
    is($r->compression_level,            undef, 'compression_level undef by default');
    is($r->compression_dictionary,       undef, 'compression_dictionary undef by default');
    is($r->compression_dictionary_file,  undef, 'compression_dictionary_file undef by default');
    is($r->keep_compressed,              0,     'keep_compressed 0 by default');
};

subtest validation => sub {
    like(
        dies { Atomic::Pipe->new(compression => 'bogus') },
        qr/Unknown compression algorithm 'bogus'/,
        'unknown algorithm croaks',
    );
    like(
        dies { Atomic::Pipe->new(compression_dictionary => 'x') },
        qr/compression_dictionary requires compression to be enabled/,
        'dict without compression croaks',
    );
    like(
        dies { Atomic::Pipe->new(compression_dictionary_file => '/tmp/x') },
        qr/compression_dictionary requires compression to be enabled/,
        'dict file without compression croaks',
    );
    like(
        dies {
            Atomic::Pipe->new(
                compression                 => 'zstd',
                compression_dictionary      => 'x',
                compression_dictionary_file => '/tmp/x',
            )
        },
        qr/mutually exclusive/,
        'both dict forms croaks',
    );
};

subtest constructor_options_stored => sub {
    my ($r, $w) = Atomic::Pipe->pair(
        compression       => 'zstd',
        compression_level => 5,
        keep_compressed   => 1,
    );
    is($r->compression,        'zstd', 'compression stored');
    is($r->compression_level,  5,      'compression_level stored');
    is($r->keep_compressed,    1,      'keep_compressed stored');
    is($w->compression,        'zstd', 'pair applied to writer too');
};

subtest compress_decompress_helpers => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');
    my $raw = "hello world" x 100;
    my $c   = $w->_compress($raw);
    isnt($c, $raw, '_compress changed the bytes');
    cmp_ok(length($c), '<', length($raw), '_compress produced smaller output for repetitive input');
    is($r->_decompress($c), $raw, 'roundtrip via _decompress');

    like(
        dies { $r->_decompress('not-a-zstd-frame-xyzzy') },
        qr/zstd decompression failed/,
        'corrupted decompress throws_invalid',
    );
};

subtest message_roundtrip_compression => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');

    # Random bytes are incompressible; this guarantees a multi-part message
    # after compression (zstd can't shrink random data significantly).
    my $multi = '';
    $multi .= chr(int(rand(256))) for 1 .. (Atomic::Pipe->PIPE_BUF * 4);
    $w->write_message($multi);
    is($r->read_message, $multi, 'multi-part compressed message round-trips');

    my $small = "tiny";
    $w->write_message($small);
    is($r->read_message, $small, 'single-part compressed message round-trips');

    $w->write_message("");
    is($r->read_message, "", 'empty compressed message round-trips');
};

subtest message_roundtrip_compression_debug => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');
    $w->write_message("payload");
    my $info = $r->read_message(debug => 1);
    is($info->{message}, "payload", 'debug mode decompresses message field');
    ok(exists $info->{parts},        'debug mode preserves parts');
    ok(exists $info->{pid},          'debug mode preserves pid');
    ok(exists $info->{tid},          'debug mode preserves tid');
};

subtest fits_in_burst_with_compression => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');

    # Highly compressible -- would exceed PIPE_BUF raw, but compress small.
    my $big_compressible = 'a' x (Atomic::Pipe->PIPE_BUF * 4);
    ok(defined $w->fits_in_burst($big_compressible),
        'highly-compressible payload fits when compressed');

    # Random-ish high-entropy -- won't compress well; use crypto-strong-ish.
    my $incompressible = '';
    $incompressible .= chr(int(rand(256))) for 1 .. (Atomic::Pipe->PIPE_BUF * 4);
    is($w->fits_in_burst($incompressible), undef,
        'incompressible payload too large returns undef');
};

subtest mixed_mode_compression => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd', mixed_data_mode => 1);

    $w->wh->autoflush(1);

    print { $w->wh } "line1\n";
    $w->write_burst("burst-payload-" . ("x" x 200));
    $w->write_message("message-payload-" . ("y" x 5000));
    print { $w->wh } "line2\n";
    close $w->wh;

    my @got;
    while (1) {
        my @r = $r->get_line_burst_or_data;
        last unless @r;
        push @got, [@r];
    }

    is(scalar @got, 4,                                              'exactly four returns');
    is($got[0], ['line', "line1\n"],                                'line1 raw');
    is($got[1], ['burst', "burst-payload-" . ("x" x 200)],          'burst decompressed');
    is($got[2], ['message', "message-payload-" . ("y" x 5000)],     'message decompressed');
    is($got[3], ['line', "line2\n"],                                'line2 raw');
};

subtest set_compression_post_construction => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    is($r->compression, undef, 'starts off');
    $r->set_compression('zstd');
    $w->set_compression('zstd', 5);
    is($r->compression,        'zstd', 'reader enabled');
    is($w->compression,        'zstd', 'writer enabled');
    is($w->compression_level,  5,      'writer level set');

    $w->write_message("hello");
    is($r->read_message, "hello", 'roundtrip after set_compression');

    $r->set_compression(undef);
    $w->set_compression(undef);
    is($r->compression, undef, 'reader disabled');
    is($w->compression, undef, 'writer disabled');

    $w->write_message("plain");
    is($r->read_message, "plain", 'roundtrip after disabling');
};

subtest set_keep_compressed_post_construction => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');
    is($r->keep_compressed, 0, 'off');
    $r->set_keep_compressed(1);
    is($r->keep_compressed, 1, 'on');
    $r->set_keep_compressed(0);
    is($r->keep_compressed, 0, 'off again');
};

subtest set_compression_validation => sub {
    my ($r, $w) = Atomic::Pipe->pair;
    like(
        dies { $r->set_compression('bogus') },
        qr/Unknown compression algorithm 'bogus'/,
        'unknown algo croaks',
    );
};


subtest dictionary_bytes_roundtrip => sub {
    plan skip_all => 'Compress::Zstd dictionary submodules unavailable' unless $HAVE_DICT;
    my $dict = ("the quick brown fox jumps over the lazy dog. " x 100);
    my ($r, $w) = Atomic::Pipe->pair(
        compression            => 'zstd',
        compression_dictionary => $dict,
    );
    is($r->compression_dictionary, $dict, 'reader stores dict');
    is($w->compression_dictionary, $dict, 'writer stores dict');

    my $msg = "the quick brown fox jumps over the lazy dog\n" x 50;
    $w->write_message($msg);
    is($r->read_message, $msg, 'dict-compressed message round-trips');
};

subtest dictionary_file_roundtrip => sub {
    plan skip_all => 'Compress::Zstd dictionary submodules unavailable' unless $HAVE_DICT;
    require File::Temp;
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    my $dict_bytes = ("alpha bravo charlie delta echo " x 100);
    print $fh $dict_bytes;
    close $fh;

    my ($r, $w) = Atomic::Pipe->pair(
        compression                 => 'zstd',
        compression_dictionary_file => $path,
    );
    is($r->compression_dictionary_file, $path, 'reader stores path');
    is($w->compression_dictionary_file, $path, 'writer stores path');

    my $msg = "alpha bravo charlie\n" x 50;
    $w->write_message($msg);
    is($r->read_message, $msg, 'file-dict-compressed message round-trips');
};

subtest dictionary_setters => sub {
    plan skip_all => 'Compress::Zstd dictionary submodules unavailable' unless $HAVE_DICT;
    require File::Temp;
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');

    my $dict = "shared dict content " x 50;
    $r->set_compression_dictionary($dict);
    $w->set_compression_dictionary($dict);
    is($r->compression_dictionary, $dict, 'set bytes works');

    $w->write_message("xyz");
    is($r->read_message, "xyz", 'roundtrip with set bytes dict');

    # Switch to file form; setter must clear the bytes form.
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    print $fh "file dict content " x 50;
    close $fh;

    $r->set_compression_dictionary_file($path);
    $w->set_compression_dictionary_file($path);
    is($r->compression_dictionary,      undef, 'bytes cleared');
    is($r->compression_dictionary_file, $path, 'file path set');

    $w->write_message("from-file");
    is($r->read_message, "from-file", 'roundtrip with file dict');

    # Clear:
    $r->set_compression_dictionary_file(undef);
    $w->set_compression_dictionary_file(undef);
    $w->write_message("no-dict");
    is($r->read_message, "no-dict", 'roundtrip with no dict');
};

subtest keep_compressed_read_message => sub {
    my ($r, $w) = Atomic::Pipe->pair(
        compression     => 'zstd',
        keep_compressed => 1,
    );
    my $msg = "data " x 1000;
    $w->write_message($msg);

    # Scalar context: backwards compatible.
    my $scalar = scalar $r->read_message;
    is($scalar, $msg, 'scalar context returns decompressed');

    # List context: ($decompressed, $compressed).
    $w->write_message($msg);
    my @lst = $r->read_message;
    is($lst[0], $msg, 'list context [0] decompressed');
    cmp_ok(length($lst[1]), '<', length($lst[0]), 'list context [1] is smaller');
    is(Compress::Zstd::decompress($lst[1]), $msg, 'list context [1] is the compressed bytes');

    # Debug context: hash gets `compressed` key.
    $w->write_message($msg);
    my $info = $r->read_message(debug => 1);
    is($info->{message}, $msg, 'debug message decompressed');
    is(Compress::Zstd::decompress($info->{compressed}), $msg, 'debug compressed key present');
};

subtest keep_compressed_mixed_mode => sub {
    my ($r, $w) = Atomic::Pipe->pair(
        compression     => 'zstd',
        keep_compressed => 1,
        mixed_data_mode => 1,
    );

    $w->wh->autoflush(1);

    my $burst = "B" x 200;
    my $msg   = "M" x 5000;
    print { $w->wh } "ln\n";
    $w->write_burst($burst);
    $w->write_message($msg);
    close $w->wh;

    my %h1 = $r->get_line_burst_or_data;
    is($h1{line}, "ln\n", 'line key');
    ok(!exists $h1{compressed}, 'no compressed key on line');

    my %h2 = $r->get_line_burst_or_data;
    is($h2{burst}, $burst, 'burst decompressed');
    is(Compress::Zstd::decompress($h2{compressed}), $burst, 'burst compressed bytes present');

    my %h3 = $r->get_line_burst_or_data;
    is($h3{message}, $msg, 'message decompressed');
    is(Compress::Zstd::decompress($h3{compressed}), $msg, 'message compressed bytes present');
};

subtest keep_compressed_without_compression => sub {
    # Per spec: keep_compressed without compression is silently ignored.
    my ($r, $w) = Atomic::Pipe->pair(keep_compressed => 1);
    $w->write_message("plain");
    my @lst = $r->read_message;
    is(\@lst, ["plain"], 'no compression: list ctx is single-element regardless of keep_compressed');
};

subtest keep_compressed_off_no_extra => sub {
    my ($r, $w) = Atomic::Pipe->pair(
        compression     => 'zstd',
        mixed_data_mode => 1,
    );

    $w->wh->autoflush(1);

    print { $w->wh } "x\n";
    $w->write_burst("y");
    close $w->wh;

    my @r1 = $r->get_line_burst_or_data;
    is(\@r1, ['line', "x\n"], 'line: only 2 elems');
    my @r2 = $r->get_line_burst_or_data;
    is(\@r2, ['burst', "y"], 'burst: only 2 elems (no keep_compressed)');
};

subtest dictionary_mismatch => sub {
    plan skip_all => 'Compress::Zstd dictionary submodules unavailable' unless $HAVE_DICT;
    # Note: zstd's raw (untrained) dictionaries don't embed a dict-ID, so a
    # mere mismatch silently yields garbage rather than an error. Verify
    # instead that the dict-aware decompress path still surfaces hard
    # corruption (truncated/garbage frames) as "zstd decompression failed".
    my ($r, $w) = Atomic::Pipe->pair(
        compression            => 'zstd',
        compression_dictionary => "dict-A" x 100,
    );

    # Positive control: dict-aware path actually round-trips a frame it produced.
    my $compressed = $w->_compress("payload");
    is($r->_decompress($compressed), "payload", 'dict-aware path round-trips');

    like(
        dies { $r->_decompress('not-a-zstd-frame-xyzzy') },
        qr/zstd decompression failed/,
        'corrupted decompress with dict throws',
    );
};

subtest corrupted_message_throws => sub {
    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');

    # Write a deliberately-not-zstd payload by going under the API.
    # write_message will compress what we give it; instead bypass via
    # disabling compression on writer just for this push, then write
    # garbage that read_message (with compression on) will try to
    # decompress.
    $w->set_compression(undef);
    $w->write_message("definitely-not-a-zstd-frame");
    $w->set_compression('zstd');

    like(
        dies { $r->read_message },
        qr/zstd decompression failed/,
        'corrupted body triggers throw_invalid',
    );
};

subtest fifo_set_compression_after_open => sub {
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $fifo = "$dir/p";
    require POSIX;
    POSIX::mkfifo($fifo, 0600) or plan skip_all => "mkfifo failed: $!";

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        my $w = Atomic::Pipe->write_fifo($fifo);
        $w->set_compression('zstd');
        $w->write_message("fifo-msg");
        exit 0;
    }

    my $r = Atomic::Pipe->read_fifo($fifo);
    $r->set_compression('zstd');
    is($r->read_message, "fifo-msg", 'roundtrip via fifo with set_compression');

    waitpid($pid, 0);
};

done_testing;
