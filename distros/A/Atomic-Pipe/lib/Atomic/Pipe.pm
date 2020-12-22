package Atomic::Pipe;
use strict;
use warnings;

our $VERSION = '0.014';

use IO();
use Carp qw/croak/;

use constant IS_WIN32 => ($^O eq 'MSWin32' ? 1 : 0);

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

use constant RH             => 'rh';
use constant WH             => 'wh';
use constant STATE          => 'state';
use constant OUT_BUFFER     => 'out_buffer';
use constant READ_BLOCKING  => 'read_blocking';
use constant WRITE_BLOCKING => 'write_blocking';
use constant BURST_PREFIX   => 'burst_prefix';
use constant BURST_POSTFIX  => 'burst_postfix';
use constant ADJUSTED_DSIZE => 'adjusted_dsize';
use constant MESSAGE_KEY    => 'message_key';
use constant MIXED_BUFFER   => 'mixed_buffer';

sub wh { shift->{+WH} }
sub rh { shift->{+RH} }

sub _get_tid {
    return 0 unless $INC{'threads.pm'};
    return threads->tid();
}

sub _fh_mode {
    my $self = shift;
    my ($fh) = @_;

    my $mode = fcntl($fh, Fcntl::F_GETFL(), 0) // return undef;
    return '<&' if $mode == Fcntl::O_RDONLY();
    return '>&' if $mode == Fcntl::O_WRONLY();
    return undef;
}

my %MODE_TO_DIR = (
    '<&'  => RH(),
    '<&=' => RH(),
    '>&'  => WH(),
    '>&=' => WH(),
);
sub _mode_to_dir {
    my $self = shift;
    my ($mode) = @_;
    return $MODE_TO_DIR{$mode};
}

sub read_fifo {
    my $class = shift;
    my ($fifo, %params) = @_;

    croak "File '$fifo' is not a pipe (-p check)" unless -p $fifo;

    open(my $fh, '+<', $fifo) or die "Could not open fifo ($fifo) for reading: $!";
    binmode($fh);

    return bless({%params, RH() => $fh}, $class);
}

sub write_fifo {
    my $class = shift;
    my ($fifo, %params) = @_;

    croak "File '$fifo' is not a pipe (-p check)" unless -p $fifo;

    open(my $fh, '>', $fifo) or die "Could not open fifo ($fifo) for writing: $!";
    binmode($fh);

    return bless({%params, WH() => $fh}, $class);
}

sub from_fh {
    my $class = shift;
    my $ifh = pop;
    my ($mode) = @_;

    croak "Filehandle is not a pipe (-p check)" unless -p $ifh;

    $mode //= $class->_fh_mode($ifh) // croak "Could not determine filehandle mode, please specify '>&' or '<&'";
    my $dir = $class->_mode_to_dir($mode) // croak "Invalid mode: $mode";

    open(my $fh, $mode, $ifh) or croak "Could not clone ($mode) filehandle: $!";
    binmode($fh);

    return bless({$dir => $fh}, $class);
}

sub from_fd {
    my $class = shift;
    my ($mode, $fd) = @_;

    my $dir = $class->_mode_to_dir($mode) // croak "Invalid mode: $mode";
    open(my $fh, $mode, $fd) or croak "Could not open ($mode) fd$fd: $!";

    croak "Filehandle is not a pipe (-p check)" unless -p $fh;

    binmode($fh);
    return bless({$dir => $fh}, $class);
}

sub new {
    my $class = shift;
    my (%params) = @_;

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    return bless({%params, RH() => $rh, WH() => $wh}, $class);
}

sub pair {
    my $class = shift;
    my (%params) = @_;

    my $mixed = delete $params{mixed_data_mode};

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    my $r = bless({%params, RH() => $rh}, $class);
    my $w = bless({%params, WH() => $wh}, $class);

    if ($mixed) {
        $r->set_mixed_data_mode();
        $w->set_mixed_data_mode();
    }

    return ($r, $w);
}

sub set_mixed_data_mode {
    my $self = shift;

    $self->read_blocking(0) if $self->{+RH};

    $self->{+BURST_PREFIX}  //= "\x0E";    # Shift out
    $self->{+BURST_POSTFIX} //= "\x0F";    # Shift in
    $self->{+MESSAGE_KEY}   //= "\x10";    # Data link escape
}

sub get_line_burst_or_data {
    my $self = shift;
    my %params = @_;

    my $rh = $self->{+RH} // croak "Not a read handle";

    my $prefix  = $self->{+BURST_PREFIX}  // croak "missing 'burst_prefix', not in mixed_data_mode";
    my $postfix = $self->{+BURST_POSTFIX} // croak "missing 'burst_postfix', not in mixed_data_mode";
    my $key     = $self->{+MESSAGE_KEY}   // croak "missing 'message_key', not in mixed_data_mode";

    my $buffer = $self->{+MIXED_BUFFER} //= {
        raw      => '',
        lines    => '',
        burst    => '',
        in_burst => 0,
        do_extra_loop => 0,
    };

    while (1) {
        my $start = length($buffer->{raw} //= '');

        if (IS_WIN32) {
            if (my $size = $self->_win32_pipe_ready()) {
                $size = $params{read_size} if $params{read_size} && $params{read_size} < $size;
                my $x = '';
                sysread($rh, $x, $size);
                $buffer->{raw} .= $x;
            }
        }
        elsif (my $size = $params{read_size}) {
            my $x = '';
            sysread($rh, $x, $size);
            $buffer->{raw} .= $x;
        }
        else {
            local $/;
            $buffer->{raw} .= <$rh> // '';
        }

        my $delta = length($buffer->{raw}) - $start;

        return () unless length($buffer->{raw}) || $buffer->{do_extra_loop};
        $buffer->{do_extra_loop}-- if $buffer->{do_extra_loop};

        if ($buffer->{strip_term}) {
            next unless $buffer->{raw};
            die "Internal Error: No Terminator?" unless substr($buffer->{raw}, 0, 1, '') eq $postfix;
            $buffer->{strip_term}--;
            next;
        }
        elsif ($buffer->{in_message}) {
            my $state = $buffer->{+STATE} //= {};

            my ($id, $message) = $self->_extract_message(
                state => $state,
                one_part_only => 1,
                read => sub {
                    if (bytes::length($buffer->{raw}) >= $_[1]) {
                        $_[0] //= '';
                        $_[0] .= bytes::substr($buffer->{raw}, 0, $_[1], '');
                        $! = 0;
                        return $_[1];
                    }

                    $! = EAGAIN;
                    return undef;
                },
            );

            next unless defined $id;

            if (substr($buffer->{raw}, 0, 1) eq $postfix) {
                substr($buffer->{raw}, 0, 1, '');
            }
            else {
                $buffer->{strip_term}++;
            }

            $buffer->{in_message} = 0;
            $buffer->{do_extra_loop}++;
            return (message => $message) if defined $message;
            next;
        }
        elsif ($buffer->{in_burst}) {
            if (substr($buffer->{raw}, 0, 1) eq $key) {
                substr($buffer->{raw}, 0, 1, ''); # Strip off the key
                $buffer->{in_message} = 1;
                $buffer->{in_burst} = 0;
                $buffer->{do_extra_loop}++;
                next;
            }

            $buffer->{burst} //= '';
            my ($burst_data, $term);
            ($burst_data, $term, $buffer->{raw}) = split /(\Q$postfix\E)/, $buffer->{raw}, 2;
            $buffer->{burst} .= $burst_data;

            if ($term) {
                $buffer->{in_burst} = 0;
                $buffer->{do_extra_loop}++;
                return (burst => delete($buffer->{burst}));
            }

            next;
        }
        else {
            # Look for the start of a burst
            $buffer->{lines} //= '';
            my $linedata;
            ($linedata, $buffer->{in_burst}, $buffer->{raw}) = split /(\Q$prefix\E)/, $buffer->{raw}, 2;
            $buffer->{lines} .= $linedata if length($linedata);

            # Look for a complete line
            my $term;
            ($linedata, $term, $buffer->{lines}) = split /(\r?\n)/, $buffer->{lines}, 2;
            if ($term) {
                $buffer->{do_extra_loop}++;
                return (line => "${linedata}${term}");
            }

            # No line found, put the linedata back in the buffer
            $buffer->{lines} = $linedata;
        }
    }
}

sub debug {
    my ($id, $buffer) = @_;

    print "---debug $id---\n";
    for my $key (sort keys %$buffer) {
        my $val = $buffer->{$key} // '<UNDEF>';
        $val =~ s/\x0E/\\x0E/g;
        $val =~ s/\x0F/\\x0F/g;
        $val =~ s/\x10/\\x10/g;
        $val =~ s/\n/\\n/g;
        $val =~ s/\r/\\r/g;
        print "$key: |$val|\n\n";
    };
}

# This is a heavily modified version of a pattern suggested on stack-overflow
# and also used in Win32::PowerShell::IPC.
my $peek_named_pipe;
sub _win32_pipe_ready {
    my $self = shift;
    my $wh = Win32API::File::FdGetOsFHandle(fileno($self->{+RH}));

    my $buf = "";
    my $buflen = 0;

    $peek_named_pipe //= Win32::API->new("kernel32", 'PeekNamedPipe', 'NPIPPP', 'N')
        || die "Can't load PeekNamedPipe from kernel32.dll";

    my $got    = pack('L', 0);
    my $avail  = pack('L', 0);
    my $remain = pack('L', 0);

    my $ret = $peek_named_pipe->Call($wh, $buf, $buflen, $got, $avail, $remain);

    return unpack('L', $avail);
}

my $set_named_pipe_handle_state;
sub _win32_set_pipe_state {
    my $self = shift;
    my ($state) = @_;
    my $wh = Win32API::File::FdGetOsFHandle(fileno($self->{+WH}));

    $set_named_pipe_handle_state //= Win32::API->new("kernel32", 'SetNamedPipeHandleState', 'NPPP', 'N')
        || die "Can't load SetNamedPipeHandleState from kernel32.dll";

    # Block or non-block?
    my $lpmode = $state ? pack('L', 0x00000000) : pack('L', 0x00000001);

    my $ret = $set_named_pipe_handle_state->Call($wh, $lpmode, +0, +0);

    return $ret;
}

my $WIN32_API_LOADED = 0;

sub _load_win32_api {
    return 1 if $WIN32_API_LOADED;

    eval { require Win32::API;     1 } or die "non-blocking on windows requires Win32::API please install it.\n$@";
    eval { require Win32API::File; 1 } or die "non-blocking on windows requires Win32API::File please install it.\n$@";

    return $WIN32_API_LOADED = 1;
}

sub read_blocking {
    my $self = shift;
    my $rh   = $self->{+RH} or croak "Not a reader";

    ($self->{+READ_BLOCKING}) = @_ if @_;

    if (IS_WIN32) {
        _load_win32_api() unless $self->{+READ_BLOCKING} || $WIN32_API_LOADED;
    }
    else {
        $rh->blocking(@_);
    }

    return $self->{+READ_BLOCKING};
}

sub write_blocking {
    my $self = shift;
    my $wh   = $self->{+WH} or croak "Not a writer";

    return $self->{+WRITE_BLOCKING} unless @_;

    my ($val) = @_;
    $self->{+WRITE_BLOCKING} = $val;

    if (IS_WIN32) {
        _load_win32_api() unless $self->{+WRITE_BLOCKING} || $WIN32_API_LOADED;
        $self->_win32_set_pipe_state(@_) if @_;
    }
    else {
        my $flags = 0;
        fcntl($wh, &Fcntl::F_GETFL, $flags) || die $!;    # Get the current flags on the filehandle
        if   ($val) { $flags ^= &Fcntl::O_NONBLOCK }      # Remove non-blocking
        else        { $flags |= &Fcntl::O_NONBLOCK }      # Add non-blocking to the flags
        fcntl($wh, &Fcntl::F_SETFL, $flags) || die $!;    # Set the flags on the filehandle
    }

    return $self->{+WRITE_BLOCKING};
}

sub blocking {
    my $self = shift;

    if ($self->{+RH} && !$self->{+WH}) {
        return $self->read_blocking(@_);
    }
    elsif ($self->{+WH} && !$self->{+RH}) {
        return $self->write_blocking(@_);
    }

    my $r = $self->read_blocking(@_);
    my $w = $self->write_blocking(@_);

    return 1 if $r && $w;
    return 0 if !$r && !$w;
    return undef;
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

sub fits_in_burst {
    my $self = shift;
    my ($data) = @_;

    my $prefix  = $self->{+BURST_PREFIX}  // '';
    my $postfix = $self->{+BURST_POSTFIX} // '';

    my $size = bytes::length($prefix . $data . $postfix);
    return undef unless $size <= PIPE_BUF;

    return $size;
}

sub write_burst {
    my $self = shift;
    my ($data) = @_;

    my $size = $self->fits_in_burst($data) // return undef;

    push @{$self->{+OUT_BUFFER} //= []} => [$data, $size];
    $self->flush();

    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->flush(blocking => 1) if $self->{+OUT_BUFFER} && @{$self->{+OUT_BUFFER}};
}

sub flush {
    my $self = shift;
    my %params = @_;
    my $blocking = $params{blocking} // $self->{+WRITE_BLOCKING} // 1;

    my $buffer = $self->{+OUT_BUFFER} // return;

    while (@$buffer) {
        my $set = $buffer->[0];
        my $got = $self->_write_burst(@$set);

        return unless $blocking || defined $got;
        next unless defined $got;

        shift @$buffer;
    }

    return;
}

sub _write_burst {
    my $self = shift;
    my ($data, $size) = @_;

    my $wh = $self->{+WH} or croak "Cannot call write on a pipe reader";

    my $prefix  = $self->{+BURST_PREFIX}  // '';
    my $postfix = $self->{+BURST_POSTFIX} // '';

    $data = "${prefix}${data}${postfix}" if length($prefix) || length($postfix);

    my $wrote;
    my $loop = 0;
    SWRITE: {
        $wrote = syswrite($wh, $data, $size);
        return undef if $! == EAGAIN || ($! == 28 && IS_WIN32); # NON-BLOCKING
        redo SWRITE if !$wrote || $RETRY_ERRNO{0 + $!};
        last SWRITE if $wrote == $size;
        $wrote //= "<NULL>";
        die "$wrote vs $size: $!";
    }

    return $wrote;
}

sub _adjusted_dsize {
    my $self = shift;

    return $self->{+ADJUSTED_DSIZE} if defined $self->{+ADJUSTED_DSIZE};

    my $message_key = $self->{+MESSAGE_KEY}   // '';
    my $prefix      = $self->{+BURST_PREFIX}  // '';
    my $postfix     = $self->{+BURST_POSTFIX} // '';

    my $fix_size = bytes::length($prefix) + bytes::length($postfix) + bytes::length($message_key);
    return $self->{+ADJUSTED_DSIZE} = $dsize - $fix_size;
}

sub parts_needed {
    my $self = shift;
    my ($data) = @_;

    my $adjusted_dsize = $self->_adjusted_dsize;

    my $dtotal = bytes::length($data);
    my $parts = int($dtotal / $adjusted_dsize);
    $parts++ if $dtotal % $adjusted_dsize;

    return $parts;
}

sub write_message {
    my $self = shift;
    my ($data) = @_;

    my $parts = $self->parts_needed($data);

    my $adjusted_dsize = $self->_adjusted_dsize;
    my $message_key = $self->{+MESSAGE_KEY} // '';

    my $id = $parts - 1;
    for (my $part = 0; $part < $parts; $part++) {
        my $bytes = bytes::substr($data, $part * $adjusted_dsize, $adjusted_dsize);
        my $size = bytes::length($bytes);
        my $out = $message_key . pack("l2L2a$size", $$, _get_tid(), $id--, $size, $bytes);

        $self->write_burst($out);
    }

    return $parts;
}

sub eof { shift->{+STATE}->{EOF} ? 1 : 0 }

sub read_message {
    my $self = shift;
    my %params = @_;

    my $state = $self->{+STATE} //= {};

    return if $state->{EOF};

    my $rh = $self->{+RH} or croak "Not a reader";

    if (IS_WIN32 && defined($self->{+READ_BLOCKING}) && !$self->{+READ_BLOCKING}) {
        return undef unless $self->_win32_pipe_ready();
    }

    my ($id, $out) = $self->_extract_message(
        %params,
        state => $state,
        read => sub {
            my $buffer = '';
            my $out = sysread($rh, $buffer, $_[1]);
            $_[0] //= '';
            $_[0] .= $buffer if $out;
            return $out;
        },
    );

    return $out if defined $id;
    return;
}

sub _extract_message {
    my $self   = shift;
    my %params = @_;
    my $state  = $params{state};
    my $read   = $params{read};

    while (1) {
        my $pb_size = $state->{pb_size} //= 0;
        while ($pb_size < $psize) {
            my $read = $read->($state->{p_buffer}, $psize - $pb_size);
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
            my $read = $read->($state->{d_buffer}, $key->{size} - $db_size);
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
        push @{$state->{parts}->{$tag} //= []} => $id;

        %$state = (
            buffers => $state->{buffers},
            parts   => $state->{parts},
            EOF     => $state->{EOF},
        );

        unless ($id == 0) {
            return ($id, undef) if $params{one_part_only};
            next;
        }

        my $message = delete $state->{buffers}->{$tag};
        my $parts   = delete $state->{parts}->{$tag};

        return ($id, $message) unless $params{debug};

        return (
            $id,
            {
                message => $message,
                parts   => $parts,
                pid     => $key->{pid},
                tid     => $key->{tid},
            },
        );
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

=head1 MIXED DATA MODE

Mixed data mode is a special use-case for Atomic::Pipe. In this mode the
assumption is that the writer end of the pipe uses the pipe as STDOUT or
STDERR, and as such a lot of random non-atomic prints can happen on the writer
end of the pipe. The special case is when you want to send atomic-chunks of
data inline with the random prints, and in the end extract the data from the
noise. The atomic nature of messages and bursts makes this possible.

Please note that mixed data mode makes use of 3 ASCII control characters:

=over 4

=item SHIFT OUT (^N or \x0E)

Used to start a burst

=item SHIFT IN (^O or \x0F)

Used to terminate a burst

=item DATA LINK ESCAPE (^P or \x10)

If this directly follows a SHIFT-OUT it marks the burst as being part of a
data-message.

=back

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

=item $r = Atomic::Pipe->read_fifo($FIFO_PATH)

=item $w = Atomic::Pipe->write_fifo($FIFO_PATH)

These 2 constructors let you connect to a FIFO by filesystem path.

The interface difference (read_fifo and write_fifo vs specifying a mode) is
because the modes to use for fifo's are not obvious (C<< '+<' >> for reading).

B<NOTE:> THERE IS NO EOF for the read-end in the process that created the fifo.
You need to figure out when the last message is received on your own somehow.
If you use blocking reads in a loop with no loop exit condition then the loop
will never end even after all writers are gone.

=item $p = Atomic::Pipe->from_fh($fh)

=item $p = Atomic::Pipe->from_fh($mode, $fh)

Create an instance around an existing filehandle (A clone of the handle will be
made and kept internally).

This will fail if the handle is not a pipe.

If no mode is provided this constructor will determine the mode (reader or
writer) for you from the given handle. B<Note:> This works on linux, but not
BSD or Solaris, on most platforms your must provide a mode.

Valid modes:

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

=item $count = $self->parts_needed($data)

Get the number of parts the data will be split into for it to be written in
atomic chunks.

=item $p->blocking($bool)

=item $bool = $p->blocking

Get/Set blocking status. This works on read and write handles. On writers this
will write as many chunks/bursts as it can, then buffer any remaining until
your next write_message(), write_burst(), or flush(), at which point it will
write as much as it can again. If the instance is garbage collected with
chunks/bursts in the buffer it will block until all can be written.

=item $w->flush()

Write any buffered items. This is only useful on writers that are in
non-blocking mode, it is a no-op everywhere else.

=item $bool = $p->eof

True if EOF (all writers are closed).

=item $p->close

Close this end of the pipe (or both ends if this is not yet split into
reader/writer pairs).

=item $undef_or_bytes = $p->fits_in_burst($data)

This will return C<undef> if the data DES NOT fit in a burst. This will return
the size of the data in bytes if it will fit in a burst.

=item $undef_or_true = $p->write_burst($data)

Attempt to write C<$data> in a single atomic burst. If the data is too big to
write atomically this method will not write any data and will return C<undef>.
If the data does fit in an atomic write then a true value will be returned.

B<Note:> YOU MUST NOT USE C<read_message()> when writing bursts. This method
sends the data as-is with no data-header or modification. This method should be
used when the other side is reading the pipe directly without an Atomic::Pipe
on the receiving end.

The primary use case of this is if you have multiple writers sending short
plain-text messages that will not exceed the atomic pipe buffer limit (minimum
of 512 bytes on systems that support atomic pipes accoring to POSIX).

=item $fh = $p->rh

=item $fh = $p->wh

Get the read or write handles.

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

=head3 MIXED DATA MODE METHODS

=over 4

=item $p->set_mixed_data_mode

Enable mixed-data mode. Also makes read-side non-blocking.

=item ($type, $data) = $r->get_line_burst_or_data()

Get a line, a burst, or a message from the pipe. Always non-blocking, will
return C<< (undef, undef) >> if no complete line/burst/message is ready.

$type will be one of: C<undef>, C<'line'>, C<'burst'>, or C<'message'>.

$data will either be C<undef>, or a complete line, burst, or message.

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
