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
    my $chunks = $w->send_message("Hello");

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

# METHODS

## CLASS METHODS

- $bytes = Atomic::Pipe->PIPE\_BUF

    Get the maximum number of bytes for an atomic write to a pipe.

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

    Get a line, a burst, or a message from the pipe. Always non-blocking, will
    return `(undef, undef)` if no complete line/burst/message is ready.

    $type will be one of: `undef`, `'line'`, `'burst'`, or `'message'`.

    $data will either be `undef`, or a complete line, burst, or message.

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
