package Atomic::Pipe;
use strict;
use warnings;

our $VERSION = '0.006';

use IO();
use Carp qw/croak/;

BEGIN {
    # POSIX says writes of 512 or less are atomic, but some platforms allow for
    # larger ones.
    require POSIX;
    if (POSIX->can('PIPE_BUF') && eval { POSIX::PIPE_BUF() }) {
        *PIPE_BUF = \&POSIX::PIPE_BUF;
    }
    else {
        *PIPE_BUF = sub() { 512 };
    }
}

use Errno qw/EINTR EAGAIN/;
my %RETRY_ERRNO;
BEGIN {
    %RETRY_ERRNO = (EINTR() => 1);
    $RETRY_ERRNO{Errno->ERESTART} = 1 if Errno->can('ERESTART');
}
use Fcntl();
require bytes;

use List::Util qw/min/;
use Scalar::Util qw/blessed/;

use constant RH    => 'rh';
use constant WH    => 'wh';
use constant STATE => 'state';

sub _get_tid {
    return 0 unless $INC{'threads.pm'};
    return threads->tid();
}

sub from_fh {
    my $class = shift;
    my ($ifh) = @_;

    croak "Filehandle is not a pipe (-p check)" unless -p $ifh;

    my ($dir, $fh);
    my $mode = fcntl($ifh, Fcntl::F_GETFL(), 0);
    if ($mode & Fcntl::O_RDONLY() || $mode == Fcntl::O_RDONLY()) {
        $dir = RH();
        open($fh, '<&', $ifh) or croak "Could not clone filehandle: $!";
    }
    elsif ($mode & Fcntl::O_WRONLY() || $mode == Fcntl::O_WRONLY()) {
        $dir = WH();
        open($fh, '>&', $ifh) or croak "Could not clone filehandle: $!";
    }
    else {
        croak "Unknown handle mode ($mode)";
    }

    binmode($fh);
    return bless({$dir => $fh}, $class);
}

sub from_fd {
    my $class = shift;
    my ($mode, $fd) = @_;

    my ($dir, $fh);
    if ($mode eq '<&' || $mode eq '<&=') {
        $dir = RH();
        open($fh, $mode, $fd) or croak "Could not open fd$fd: $!";
    }
    elsif ($mode eq '>&' || '>&=') {
        $dir = WH();
        open($fh, $mode, $fd) or croak "Could not clone fd$fd: $!";
    }
    else {
        croak "Invalid mode: $mode";
    }

    croak "Filehandle is not a pipe (-p check)" unless -p $fh;

    binmode($fh);
    return bless({$dir => $fh}, $class);
}

sub new {
    my $class = shift;

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    return bless({RH() => $rh, WH() => $wh}, $class);
}

sub pair {
    my $class = shift;

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    return (
        bless({RH() => $rh}, $class),
        bless({WH() => $wh}, $class),
    );
}

sub blocking {
    my $self = shift;
    my $rh = $self->{+RH} or croak "Not a reader";
    $rh->blocking(@_);
}

sub size {
    my $self = shift;
    return unless defined &Fcntl::F_GETPIPE_SZ;
    my $fh = $self->{+WH} // $self->{+RH};
    fcntl($fh, Fcntl::F_GETPIPE_SZ(), 0);
}

sub resize {
    my $self = shift;
    my ($size) = @_;

    return unless defined &Fcntl::F_SETPIPE_SZ;
    my $fh = $self->{+WH} // $self->{+RH};

    fcntl($fh, Fcntl::F_SETPIPE_SZ(), $size);
}

my $ONE_MB = 1 * 1024 * 1024;

sub max_size {
    return $ONE_MB unless -e '/proc/sys/fs/pipe-max-size';

    open(my $max, '<', '/proc/sys/fs/pipe-max-size') or return $ONE_MB;
    chomp(my $val = <$max>);
    close($max);
    return $val || $ONE_MB;
}

sub resize_or_max {
    my $self = shift;
    my ($size) = @_;
    $size = min($size, $self->max_size);
    $self->resize($size);
}

sub is_reader {
    my $self = shift;
    return 1 if $self->{+RH} && !$self->{+WH};
    return undef;
}

sub is_writer {
    my $self = shift;
    return 1 if $self->{+WH} && !$self->{+RH};
    return undef;
}

sub clone_writer {
    my $self = shift;
    my $class = blessed($self);
    open(my $fh, '>&:raw', $self->{+WH}) or die "Could not clone filehandle: $!";
    return bless({WH() => $fh}, $class);
}

sub clone_reader {
    my $self = shift;
    my $class = blessed($self);
    open(my $fh, '<&:raw', $self->{+RH}) or die "Could not clone filehandle: $!";
    return bless({RH() => $fh}, $class);
}

sub writer {
    my $self = shift;

    croak "pipe was set to reader, cannot set to writer" unless $self->{+WH};

    return 1 unless $self->{+RH};

    close(delete $self->{+RH});
    return 1;
}

sub reader {
    my $self = shift;

    croak "pipe was set to writer, cannot set to reader" unless $self->{+RH};

    return 1 unless $self->{+WH};

    close(delete $self->{+WH});
    return 1;
}

sub close {
    my $self = shift;
    close(delete $self->{+WH}) if $self->{+WH};
    close(delete $self->{+RH}) if $self->{+RH};
    return;
}

my $psize = 16; # 32bit pid, 32bit tid, 32 bit size, 32 bit int part id;
my $dsize = PIPE_BUF - $psize;

sub write_message {
    my $self = shift;
    my ($data) = @_;

    my $wh = $self->{+WH} or croak "Cannot call write on a pipe reader";

    my $dtotal = bytes::length($data);

    my $parts = int($dtotal / $dsize);
    $parts++ if $dtotal % $dsize;

    my $id = $parts - 1;
    for (my $part = 0; $part < $parts; $part++) {
        my $bytes = bytes::substr($data, $part * $dsize, $dsize);
        my $size = bytes::length($bytes);
        my $out = pack("l2L2a$size", $$, _get_tid(), $id--, $size, $bytes);
        my $write = $size + $psize;

        SWRITE: {
            my $wrote = syswrite($wh, $out, $write);
            redo SWRITE if !$wrote || $RETRY_ERRNO{0 + $!};
            last SWRITE if $wrote == $write;
            $wrote //= "<NULL>";
            die "$wrote vs $write: $!";
        }

    }

    return $parts;
}

sub eof { shift->{+STATE}->{EOF} ? 1 : 0 }

sub read_message {
    my $self = shift;

    my $state = $self->{+STATE} //= {};

    return if $state->{EOF};

    my $rh = $self->{+RH} or croak "Not a reader";

    while (1) {
        my $pb_size = $state->{pb_size} //= 0;
        while ($pb_size < $psize) {
            my $read = sysread($rh, $state->{p_buffer}, $psize - $pb_size);
            unless (defined $read) {
                return if $! == EAGAIN; # NON-BLOCKING
                next if $RETRY_ERRNO{0 + $!};
                croak "Error $!";
            }

            unless ($read) {
                $state->{EOF} = 1;
                return;
            }

            $pb_size = $state->{pb_size} += $read;
        }

        unless ($state->{key}) {
            my %key;
            @key{qw/pid tid id size/} = unpack('l2L2', $state->{p_buffer});
            $state->{key} = \%key;
        }

        my $key = $state->{key};
        my $db_size = $state->{db_size} //= 0;
        while ($db_size < $key->{size}) {
            my $read = sysread($rh, $state->{d_buffer}, $key->{size} - $db_size);
            unless (defined $read) {
                return if $! == EAGAIN; # NON-BLOCKING
                next if $RETRY_ERRNO{0 + $!};
                croak "Error $!";
            }

            unless ($read) {
                $state->{EOF} = 1;
                return;
            }

            $db_size = $state->{db_size} += $read;
        }

        my $id = $key->{id};
        my $tag = join ':' => @{$key}{qw/pid tid/};
        $state->{buffers}->{$tag} = $state->{buffers}->{$tag} ? $state->{buffers}->{$tag} . $state->{d_buffer} : $state->{d_buffer};

        %$state = (
            buffers => $state->{buffers},
            EOF     => $state->{EOF},
        );

        next unless $id == 0;
        my $message = delete $state->{buffers}->{$tag};
        return $message;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Atomic::Pipe - Send atomic messages from multiple writers across a POSIX pipe.

=head1 DESCRIPTION

Normally if you write to a pipe from multiple processes/threads, the messages
will come mixed together unpredictably. Some messages may be interrupted by
parts of messages from other writers. This module takes advantage of some POSIX
specifications to allow multiple writers to send arbitrary data down a pipe in
atomic chunks to avoid the issue.

B<NOTE:> This only works for POSIX compliant pipes on POSIX compliant systems.
Also some features may not be available on older systems, or some platforms.

Also: L<https://man7.org/linux/man-pages/man7/pipe.7.html>

    POSIX.1 says that write(2)s of less than PIPE_BUF bytes must be
    atomic: the output data is written to the pipe as a contiguous
    sequence.  Writes of more than PIPE_BUF bytes may be nonatomic: the
    kernel may interleave the data with data written by other processes.
    POSIX.1 requires PIPE_BUF to be at least 512 bytes.  (On Linux,
    PIPE_BUF is 4096 bytes.) [...]

Under the hood this module will split your message into small sections of
slightly smaller than the PIPE_BUF limit. Each message will be sent as 1 atomic
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

=head1 SYNOPSIS

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

=head1 METHODS

=head2 CLASS METHODS

=over 4

=item $bytes = Atomic::Pipe->PIPE_BUF

Get the maximum number of bytes for an atomic write to a pipe.

=item ($r, $w) = Atomic::Pipe->pair

Create a pipe, returns a list consisting of a reader and a writer.

=item $p = Atomic::Pipe->new

If you really must have a C<new()> method it is here for you to abuse. The
returned pipe has both handles, it is your job to then turn it into 2 clones
one with the reader and one with the writer. It is also your job to make you do
not have too many handles floating around preventing an EOF.

=item $p = Atomic::Pipe->from_fh($fh)

Create an instance around an existing filehandle (A clone of the handle will be
made and kept internally).

This will fail if the handle is not a pipe. This constructor will determine the
mode (reader or writer) for you from the given handle.

=item $p = Atomic::Pipe->from_fd($mode, $fd)

C<$fd> must be a file descriptor number.

This will fail if the fd is not a pipe.

You must specify one of these modes (as a string):

=over 4

=item '>&'

Write-only.

=item '>&='

Write-only and reuse fileno.

=item '<&'

Read-only.

=item '<&='

Read-only and reuse fileno.

=back

=back

=head2 OBJECT METHODS

=head3 PRIMARY INTERFACE

=over 4

=item $p->write_message($msg)

Send a message in atomic chunks.

=item $msg = $p->read_message

Get the next message. This will block until a message is received unless you
set C<< $p->blocking(0) >>. If blocking is turned off, and no message is ready,
this will return undef. This will also return undef when the pipe is closed
(EOF).

=item $p->blocking($bool)

=item $bool = $p->blocking

Get/Set blocking status.

=item $bool = $p->eof

True if EOF (all writers are closed).

=item $p->close

Close this end of the pipe (or both ends if this is not yet split into
reader/writer pairs).

=back

=head3 RESIZING THE PIPE BUFFER

On some newer linux systems it is possible to get/set the pipe size. On
supported systems these allow you to do that, on other systems they are no-ops,
and any that return a value will return undef.

B<Note:> This has nothing to do with the similarly named C<PIPE_BUF> which
cannot be changed. This simply effects how much data can sit in a pipe before
the writers block, it does not effect the max size of atomic writes.

=over 4

=item $bytes = $p->size

Current size of the pipe buffer.

=item $bytes = $p->max_size

Maximum size, or undef if that cannot be determined. (Linux only for now).

=item $p->resize($bytes)

Attempt to set the pipe size in bytes. It may not work, so check
C<< $p->size >>.

=item $p->resize_or_max($bytes)

Attempt to set the pipe to the specified size, but if the size is larger than
the maximum fall back to the maximum size instead.

=back

=head3 SPLITTING THE PIPE INTO READER AND WRITER

If you used C<< Atomic::Pipe->new() >> you need to now split the one object
into readers and writers. These help you do that.

=over 4

=item $bool = $p->is_reader

This returns true if this instance is ONLY a reader.

=item $p->is_writer

This returns true if this instance is ONLY a writer.

=item $p->clone_reader

This copies the object into a reader-only copy.

=item $p->clone_writer

This copies the object into a writer-only copy.

=item $p->reader

This turnes the object into a reader-only. Note that if you have no
writer-copies then effectively makes it impossible to write to the pipe as you
cannot get a writer anymore.

=item $p->writer

This turnes the object into a writer-only. Note that if you have no
reader-copies then effectively makes it impossible to read from the pipe as you
cannot get a reader anymore.

=back

=head1 SOURCE

The source code repository for Atomic-Pipe can be found at
L<http://github.com/exodist/Atomic-Pipe>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
