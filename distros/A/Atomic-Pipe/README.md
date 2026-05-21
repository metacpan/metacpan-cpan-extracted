# NAME

Atomic::Pipe - Send atomic messages from multiple writers across a POSIX pipe.

# DESCRIPTION

Normally if you write to a pipe from multiple processes/threads, the messages
will come mixed together unpredictably. Some messages may be interrupted by
parts of messages from other writers. This module takes advantage of some POSIX
specifications to allow multiple writers to send arbitrary data down a pipe in
atomic chunks to avoid the issue.

**NOTE:** This only works for POSIX compliant pipes on POSIX compliant systems.
Also some features may not be available on older systems, or some platforms.

Also: [https://man7.org/linux/man-pages/man7/pipe.7.html](https://man7.org/linux/man-pages/man7/pipe.7.html)

    POSIX.1 says that write(2)s of less than PIPE_BUF bytes must be
    atomic: the output data is written to the pipe as a contiguous
    sequence.  Writes of more than PIPE_BUF bytes may be nonatomic: the
    kernel may interleave the data with data written by other processes.
    POSIX.1 requires PIPE_BUF to be at least 512 bytes.  (On Linux,
    PIPE_BUF is 4096 bytes.) [...]

Under the hood this module will split your message into small sections of
slightly smaller than the PIPE\_BUF limit. Each message will be sent as 1 atomic
chunk with a 4 byte prefix indicating what process id it came from, what thread
id it came from, a chunk ID (in descending order, so if there are 3 chunks the
first will have id 2, the second 1, and the final chunk is always 0 allowing a
flush as it knows it is done) and then 1 byte with the length of the data
section to follow.

On the receiving end this module will read chunks and re-assemble them based on
the header data. So the reader will always get complete messages. Note that
message order is not guarenteed when messages are sent from multiple processes
or threads. Though all messages from any given thread/process should be in
order.

# SYNOPSIS

    use Atomic::Pipe;

    my ($r, $w) = Atomic::Pipe->pair;

    # Chunks will be set to the number of atomic chunks the message was split
    # into. It is fine to ignore the value returned, it will always be an
    # integer 1 or larger.
    my $chunks = $w->write_message("Hello");

    # $msg now contains "Hello";
    my $msg = $r->read_message;

    # Note, you can set the reader to be non-blocking:
    $r->blocking(0);

    # Writer too (but buffers unwritten items until your next write_burst(),
    # write_message(), or flush(), or will do a writing block when the pipe
    # instance is destroyed.
    $w->blocking(0);

    # $msg2 will be undef as no messages were sent, and blocking is turned off.
    my $msg2 = $r->read_message;

Fork example from tests:

    use Test2::V0;
    use Test2::Require::RealFork;
    use Test2::IPC;
    use Atomic::Pipe;

    my ($r, $w) = Atomic::Pipe->pair;

    # For simplicty
    $SIG{CHLD} = 'IGNORE';

    # Forks and runs your coderef, then exits.
    sub worker(&) { ... }

    worker { is($w->write_message("aa" x $w->PIPE_BUF), 3, "$$ Wrote 3 chunks") };
    worker { is($w->write_message("bb" x $w->PIPE_BUF), 3, "$$ Wrote 3 chunks") };
    worker { is($w->write_message("cc" x $w->PIPE_BUF), 3, "$$ Wrote 3 chunks") };

    my @messages = ();
    push @messages => $r->read_message for 1 .. 3;

    is(
        [sort @messages],
        [sort(('aa' x PIPE_BUF), ('bb' x PIPE_BUF), ('cc' x PIPE_BUF))],
        "Got all 3 long messages, not mangled or mixed, order not guarenteed"
    );

    done_testing;

Optional Zstd compression for bursts and messages (both ends must agree):

    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');
    $w->write_message($big_payload);   # compressed on the wire
    my $msg = $r->read_message;        # decompressed transparently

See ["COMPRESSION"](#compression) for details and options.

# MIXED DATA MODE

Mixed data mode is a special use-case for Atomic::Pipe. In this mode the
assumption is that the writer end of the pipe uses the pipe as STDOUT or
STDERR, and as such a lot of random non-atomic prints can happen on the writer
end of the pipe. The special case is when you want to send atomic-chunks of
data inline with the random prints, and in the end extract the data from the
noise. The atomic nature of messages and bursts makes this possible.

Please note that mixed data mode makes use of 3 ASCII control characters:

- SHIFT OUT (^N or \\x0E)

    Used to start a burst

- SHIFT IN (^O or \\x0F)

    Used to terminate a burst

- DATA LINK ESCAPE (^P or \\x10)

    If this directly follows a SHIFT-OUT it marks the burst as being part of a
    data-message.

If the random prints include SHIFT OUT then they will confuse the read-side
parser and it will not be possible to extract data, in fact reading from the
pipe will become quite unpredictable. In practice this is unlikely to cause
issues, but printing a binary file or random noise could do it.

A burst may not include SHIFT IN as the SHIFT IN control+character marks the
end of a burst. A burst may also not start with the DATA LINK ESCAPE control
character as that is used to mark the start of a data-message.

data-messages may contain any data/characters/bytes as they messages include a
length so an embedded SHIFT IN will not terminate things early.

    # Create a pair in mixed-data mode
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);

    # Open STDOUT to the write handle
    open(STDOUT, '>&', $w->{wh}) or die "Could not clone write handle: $!";

    # For sanity
    $wh->autoflush(1);

    print "A line!\n";

    print "Start a line ..."; # Note no "\n"

    # Any number of newlines is fine the message will send/recieve as a whole.
    $w->write_burst("This is a burst message\n\n\n");

    # Data will be broken into atomic chunks and sent
    $w->write_message($data);

    print "... Finish the line we started earlier\n";

    my ($type, $data) = $r->get_line_burst_or_data;
    # Type: 'line'
    # Data: "A line!\n"

    ($type, $data) = $r->get_line_burst_or_data;
    # Type: 'burst'
    # Data: "This is a burst message\n\n\n"

    ($type, $data) = $r->get_line_burst_or_data;
    # Type: 'message'
    # Data: $data

    ($type, $data) = $r->get_line_burst_or_data;
    # Type: 'line'
    # Data: "Start a line ...... Finish the line we started earlier\n"

    # mixed-data mode is always non-blocking
    ($type, $data) = $r->get_line_burst_or_data;
    # Type: undef
    # Data: undef

You can also turn mixed-data mode after construction, but you must do so on both ends:

    $r->set_mixed_data_mode();
    $w->set_mixed_data_mode();

Doing so will make the pipe non-blocking, and will make all bursts/messages
include the necessary control characters.

# COMPRESSION

`Atomic::Pipe` can transparently compress **bursts** and **messages** (including
in mixed-data mode) with Zstandard. Plain `print $wh ...` traffic is **not**
compressed. Both ends of the pipe must be configured the same way; mismatch
produces protocol errors (or, in the case of mismatched dictionaries, silent
corruption -- see ["Custom dictionary"](#custom-dictionary) below).

Requires [Compress::Zstd](https://metacpan.org/pod/Compress%3A%3AZstd) (a soft / recommended dependency, loaded only when
compression is enabled).

## Constructor options

All constructors (`new`, `pair`, `from_fh`, `from_fd`, `read_fifo`,
`write_fifo`) accept:

- compression => 'zstd'

    Enable Zstd compression. Currently `'zstd'` is the only supported algorithm;
    any other value croaks at construction.

- compression\_level => $level

    Zstd compression level, defaults to 3. Only meaningful when `compression` is
    enabled.

- compression\_dictionary => $bytes

    Optional shared Zstd dictionary, supplied as raw bytes. Both ends must use the
    same dictionary content. Mutually exclusive with `compression_dictionary_file`.

- compression\_dictionary\_file => $path

    Same as `compression_dictionary` but loaded from a file via
    ["new\_from\_file" in Compress::Zstd::CompressionDictionary](https://metacpan.org/pod/Compress%3A%3AZstd%3A%3ACompressionDictionary#new_from_file). The file is read on
    demand.

- keep\_compressed => $bool

    When set together with `compression`, reads expose the on-wire compressed
    bytes alongside the decompressed payload. See ["read\_message"](#read_message) and
    ["get\_line\_burst\_or\_data"](#get_line_burst_or_data) for the exact return-shape changes. Has no effect
    without `compression`.

## Custom dictionary

Custom Zstd dictionaries can dramatically reduce frame size for small,
repetitive payloads. Either form (bytes or file) may be supplied at
construction or via ["set\_compression\_dictionary"](#set_compression_dictionary) /
["set\_compression\_dictionary\_file"](#set_compression_dictionary_file).

**Caveat:** raw zstd dictionaries do not embed a dict-ID. As a result a
**mismatched** peer dictionary will silently decode to garbage rather than
fail. (Hard frame corruption -- truncated or invalid frames -- still raises
fatally.) Both ends must agree on byte-identical dictionary content.

## Performance

Compression is not just a wire-size optimization for `Atomic::Pipe`: when
messages exceed `PIPE_BUF` (typically 4096 bytes on Linux) the writer must
fragment them into multiple non-atomic chunks, and the reader must reassemble
them. Compressing the payload first frequently collapses a multi-part message
back into a single atomic burst, which avoids that per-message protocol
overhead entirely. As a result, on workloads dominated by larger-than-PIPE\_BUF
messages, compression is often **much faster end-to-end than no compression**,
even after accounting for the CPU cost of compress/decompress.

The kernel pipe buffer size (see ["resize"](#resize)) does **not** affect this --
fragmentation is keyed on the POSIX `PIPE_BUF` atomic-write threshold, not on
the buffer capacity.

### Benchmark: streaming JSON objects

Numbers below are from `bench/zstd_compression.pl` in the distribution. The
workload is a synthetic but representative stream of JSON log/event objects
sent in mixed-data mode via `write_message`. The corpus is generated once and
reused across all runs; sizes are JSON-encoded byte counts.

Two corpora were measured:

- Small JSON (10 MB total, 11785 objects)

    Object sizes 181 .. 1977 bytes, average ~890 B; ~37% of objects under 500 B.
    Most messages fit in a single `PIPE_BUF` burst regardless of compression.

        level     raw MB/s   wire MB    ratio   saved
        plain         9.74    10.00       -        -
        L-3          15.98     6.68    1.50x    33.2%
        L1           24.55     4.92    2.03x    50.8%
        L3 (def)     27.79     4.91    2.04x    50.9%
        L5           46.34     4.87    2.05x    51.3%
        L7           63.72     4.87    2.05x    51.3%
        L12          27.02     4.85    2.06x    51.5%
        L22          14.43     4.84    2.07x    51.6%

    For this size distribution, levels 1..7 are all faster than no compression
    (pipe back-pressure on the uncompressed run still dominates).

- Larger JSON (100 MB total, 20407 objects)

    Object sizes 187 .. 10000 bytes, average ~5.1 KB, evenly distributed across
    the 1..10 KB range. Most objects exceed `PIPE_BUF`, so the uncompressed path
    pays the multi-part fragmentation cost on nearly every message.

        level     raw MB/s   wire MB    ratio   saved
        plain         0.29   100.00       -        -
        L-3         287.85    35.61    2.81x    64.4%
        L-1         273.56    33.92    2.95x    66.1%
        L1          237.04    30.56    3.27x    69.4%
        L3 (def)    207.61    30.25    3.31x    69.7%
        L5          113.02    30.01    3.33x    70.0%
        L9           39.35    29.93    3.34x    70.1%
        L18           7.81    28.14    3.55x    71.9%
        L22           7.85    28.14    3.55x    71.9%

    Here the uncompressed run collapses to ~0.29 MB/s, while even modest
    compression levels achieve 200+ MB/s -- a ~1000x throughput improvement
    driven almost entirely by avoided fragmentation. Levels above ~5 trade
    significant CPU for negligible additional ratio.

- Pipe buffer size has minimal impact

    The same 100 MB corpus, holding mode constant and varying the kernel pipe
    buffer (32 KB, 128 KB, 512 KB, 1 MB), shows almost no movement in either
    direction. The bottleneck is `PIPE_BUF`-aligned framing, not buffer fill, so
    calling ["resize"](#resize) with a larger size will not rescue an uncompressed
    large-message workload.

### Practical guidance

- If your messages are routinely larger than `PIPE_BUF` (~4 KB), enabling
compression is almost always a throughput win, not just a bandwidth win.
- For mixed JSON-like payloads, **level 1** or the default **level 3** are good
starting points. Level -3 is the throughput champion when CPU is precious and
some ratio can be sacrificed.
- Levels above ~7 buy single-digit-percent ratio gains for multi-x CPU cost; in
an IPC path they are rarely worth it.
- A custom dictionary (["Custom dictionary"](#custom-dictionary)) helps most when payloads are
small and share structure -- e.g. identical JSON keys across every message.

These results depend heavily on payload entropy and CPU. Re-run
`bench/zstd_compression.pl` against a representative slice of your own data
before committing to a level.

# METHODS

## CLASS METHODS

- $bytes = Atomic::Pipe->PIPE\_BUF

    Get the maximum number of bytes for an atomic write to a pipe.

- $bool = Atomic::Pipe->HAVE\_IO\_SELECT

    True if [IO::Select](https://metacpan.org/pod/IO%3A%3ASelect) is available on this system. When available, it is used by
    default in `fill_buffer()` to efficiently wait for pipe readability instead of
    relying on blocking `sysread()` with an EINTR retry loop.

- ($r, $w) = Atomic::Pipe->pair

    Create a pipe, returns a list consisting of a reader and a writer.

- $p = Atomic::Pipe->new

    If you really must have a `new()` method it is here for you to abuse. The
    returned pipe has both handles, it is your job to then turn it into 2 clones
    one with the reader and one with the writer. It is also your job to make you do
    not have too many handles floating around preventing an EOF.

- $r = Atomic::Pipe->read\_fifo($FIFO\_PATH)
- $w = Atomic::Pipe->write\_fifo($FIFO\_PATH)

    These 2 constructors let you connect to a FIFO by filesystem path.

    The interface difference (read\_fifo and write\_fifo vs specifying a mode) is
    because the modes to use for fifo's are not obvious (`'+<'` for reading).

    **NOTE:** THERE IS NO EOF for the read-end in the process that created the fifo.
    You need to figure out when the last message is received on your own somehow.
    If you use blocking reads in a loop with no loop exit condition then the loop
    will never end even after all writers are gone.

- $p = Atomic::Pipe->from\_fh($fh)
- $p = Atomic::Pipe->from\_fh($mode, $fh)

    Create an instance around an existing filehandle (A clone of the handle will be
    made and kept internally).

    This will fail if the handle is not a pipe.

    If no mode is provided this constructor will determine the mode (reader or
    writer) for you from the given handle. **Note:** This works on linux, but not
    BSD or Solaris, on most platforms your must provide a mode.

    Valid modes:

    - '>&'

        Write-only.

    - '>&='

        Write-only and reuse fileno.

    - '<&'

        Read-only.

    - '<&='

        Read-only and reuse fileno.

- $p = Atomic::Pipe->from\_fd($mode, $fd)

    `$fd` must be a file descriptor number.

    This will fail if the fd is not a pipe.

    You must specify one of these modes (as a string):

    - '>&'

        Write-only.

    - '>&='

        Write-only and reuse fileno.

    - '<&'

        Read-only.

    - '<&='

        Read-only and reuse fileno.

## OBJECT METHODS

### PRIMARY INTERFACE

- $p->write\_message($msg)

    Send a message in atomic chunks.

- $msg = $p->read\_message

    Get the next message. This will block until a message is received unless you
    set `$p->blocking(0)`. If blocking is turned off, and no message is ready,
    this will return undef. This will also return undef when the pipe is closed
    (EOF).

    When `compression` and `keep_compressed` are both enabled, list-context calls
    additionally return the raw on-wire compressed bytes:

        my ($message, $compressed) = $p->read_message;

    In `debug => 1` mode the returned hashref gains a `compressed` key
    holding the raw compressed bytes. Scalar-context calls always return just the
    decompressed message, regardless of `keep_compressed`.

- $p->blocking($bool)
- $bool = $p->blocking

    Get/Set blocking status. This works on read and write handles. On writers this
    will write as many chunks/bursts as it can, then buffer any remaining until
    your next write\_message(), write\_burst(), or flush(), at which point it will
    write as much as it can again. If the instance is garbage collected with
    chunks/bursts in the buffer it will block until all can be written.

- $bool = $p->pending\_output

    True if the pipe is a non-blocking writer and there is pending output waiting
    for a flush (and for the pipe to have room for the new data).

- $w->flush()

    Write any buffered items. This is only useful on writers that are in
    non-blocking mode, it is a no-op everywhere else.

- $bool = $r->eof()

    True if all writers are closed, and the buffers do not contain any usable data.

    Usable data means raw data that has yet to be processed, complete messages, or
    complete data bursts. Any of these can still be retreieved using
    `read_message()`, or `get_line_burst_or_data()`.

- $p->close

    Close this end of the pipe (or both ends if this is not yet split into
    reader/writer pairs).

- $undef\_or\_bytes = $p->fits\_in\_burst($data)

    This will return `undef` if the data DES NOT fit in a burst. This will return
    the size of the data in bytes if it will fit in a burst.

- $undef\_or\_true = $p->write\_burst($data)

    Attempt to write `$data` in a single atomic burst. If the data is too big to
    write atomically this method will not write any data and will return `undef`.
    If the data does fit in an atomic write then a true value will be returned.

    **Note:** YOU MUST NOT USE `read_message()` when writing bursts. This method
    sends the data as-is with no data-header or modification. This method should be
    used when the other side is reading the pipe directly without an Atomic::Pipe
    on the receiving end.

    The primary use case of this is if you have multiple writers sending short
    plain-text messages that will not exceed the atomic pipe buffer limit (minimum
    of 512 bytes on systems that support atomic pipes accoring to POSIX).

- $fh = $p->rh
- $fh = $p->wh

    Get the read or write handles.

- $read\_size = $p->read\_size()
- $p->read\_size($read\_size)

    Get/set the read size. This is how much data to ATTEMPT to read each time
    `fill_buffer()` is called. The default is 65,536 which is the default pipe
    size on linux, though the value is hardcoded currently.

- $bool = $p->use\_io\_select
- $p->use\_io\_select($bool)

    Get/Set whether this pipe instance uses [IO::Select](https://metacpan.org/pod/IO%3A%3ASelect) for readability checks in
    `fill_buffer()`. When true (and IO::Select is available), `fill_buffer()` uses
    `IO::Select->can_read()` to wait for data. When false, it falls back to a
    blocking `sysread()` with an EINTR retry loop.

    Defaults to true if IO::Select is installed (false on Windows, where
    `PeekNamedPipe` is used instead). Can also be passed as a constructor
    parameter, e.g. `Atomic::Pipe->pair(use_io_select => 0)`.

- $bytes = $p->fill\_buffer

    Read a chunk of data from the pipe and store it in the internal buffer. Bytes
    read are returned. This is only useful if you want to pull data out of the pipe
    (maybe to unblock the writer?) but do not want to process any of the data yet.

    This is automatically called as needed by other methods, usually you do not
    need to use it directly.

### RESIZING THE PIPE BUFFER

On some newer linux systems it is possible to get/set the pipe size. On
supported systems these allow you to do that, on other systems they are no-ops,
and any that return a value will return undef.

**Note:** This has nothing to do with the similarly named `PIPE_BUF` which
cannot be changed. This simply effects how much data can sit in a pipe before
the writers block, it does not effect the max size of atomic writes.

- $bytes = $p->size

    Current size of the pipe buffer.

- $bytes = $p->max\_size

    Maximum size, or undef if that cannot be determined. (Linux only for now).

- $p->resize($bytes)

    Attempt to set the pipe size in bytes. It may not work, so check
    `$p->size`.

- $p->resize\_or\_max($bytes)

    Attempt to set the pipe to the specified size, but if the size is larger than
    the maximum fall back to the maximum size instead.

### SPLITTING THE PIPE INTO READER AND WRITER

If you used `Atomic::Pipe->new()` you need to now split the one object
into readers and writers. These help you do that.

- $bool = $p->is\_reader

    This returns true if this instance is ONLY a reader.

- $p->is\_writer

    This returns true if this instance is ONLY a writer.

- $p->clone\_reader

    This copies the object into a reader-only copy.

- $p->clone\_writer

    This copies the object into a writer-only copy.

- $p->reader

    This turnes the object into a reader-only. Note that if you have no
    writer-copies then effectively makes it impossible to write to the pipe as you
    cannot get a writer anymore.

- $p->writer

    This turnes the object into a writer-only. Note that if you have no
    reader-copies then effectively makes it impossible to read from the pipe as you
    cannot get a reader anymore.

### MIXED DATA MODE METHODS

- $p->set\_mixed\_data\_mode

    Enable mixed-data mode. Also makes read-side non-blocking.

- ($type, $data) = $r->get\_line\_burst\_or\_data()
- ($type, $data) = $r->get\_line\_burst\_or\_data(peek\_line => 1)

    Get a line, a burst, or a message from the pipe. Always non-blocking, will
    return `(undef, undef)` if no complete line/burst/message is ready.

    $type will be one of: `undef`, `'line'`, `'burst'`, `'message'`, or `'peek'`.

    $data will either be `undef`, or a complete line, burst, message, or a buffered line that has no newline termination.

    The `peek_line` option, when true, will cause this to return `'peek'` and a
    buffered line not terminated by a newline, if such a line has been read and is
    pending in the buffer. Calling this multiple times will return the same peek
    line (and anything added to the buffer since the last read) until the buffer
    reads a newline or hits EOF.

    When `compression` and `keep_compressed` are both enabled, the `burst` and
    `message` return paths additionally yield a `compressed => $raw_bytes`
    pair:

        (burst   => $decompressed, compressed => $raw)
        (message => $decompressed, compressed => $raw)

    The `line` and `peek` paths never include a `compressed` key. The 2-tuple
    idiom

        my ($type, $data) = $p->get_line_burst_or_data;

    remains valid; the extra elements are simply discarded.

### COMPRESSION METHODS

- $algo\_or\_undef = $p->compression
- $level\_or\_undef = $p->compression\_level
- $bytes\_or\_undef = $p->compression\_dictionary
- $path\_or\_undef = $p->compression\_dictionary\_file
- $bool = $p->keep\_compressed

    Read-only accessors for the corresponding compression settings. See
    ["COMPRESSION"](#compression).

- $p->set\_compression('zstd', $level)
- $p->set\_compression(undef)

    Enable, change, or disable compression on an existing pipe. `$level` is
    optional; calling `$p->set_compression('zstd')` with no level preserves
    whatever level was previously set. To reset the level to its default, call
    `$p->set_compression(undef)` first (which clears compression, level,
    and any cached compressors), then re-enable.

    `set_compression(undef)` does **not** clear `compression_dictionary` or
    `compression_dictionary_file`; the dictionary is preserved across
    disable/re-enable. Use the dictionary setters to clear those slots.

- $p->set\_compression\_dictionary($bytes)
- $p->set\_compression\_dictionary(undef)

    Set, replace, or clear the raw-bytes dictionary. Setting clears any
    file-path dictionary (mutually exclusive). Cached preprocessed dictionaries
    are rebuilt on next compress/decompress.

- $p->set\_compression\_dictionary\_file($path)
- $p->set\_compression\_dictionary\_file(undef)

    Set, replace, or clear the file-path dictionary. Setting clears any
    raw-bytes dictionary.

- $p->set\_keep\_compressed($bool)

    Toggle whether reads expose the raw compressed bytes alongside the
    decompressed payload.

# SOURCE

The source code repository for Atomic-Pipe can be found at
[http://github.com/exodist/Atomic-Pipe](http://github.com/exodist/Atomic-Pipe).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2020 Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/)
