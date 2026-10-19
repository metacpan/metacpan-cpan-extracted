package Atomic::Pipe;
use strict;
use warnings;

our $VERSION = '0.033';

use IO();
use IO::Handle();
use Fcntl();
use bytes();

BEGIN {
    if (eval { require IO::Select; 1 }) {
        *HAVE_IO_SELECT = sub() { 1 };
    }
    else {
        *HAVE_IO_SELECT = sub() { 0 };
    }
}

use Carp qw/croak confess/;
use Config qw/%Config/;
use List::Util qw/min/;
use Scalar::Util qw/blessed/;

use Errno qw/EINTR EAGAIN EPIPE/;
my (%RETRY_ERRNO, %NONBLOCK_ERRNO);
BEGIN {
    %RETRY_ERRNO = (EINTR() => 1);
    $RETRY_ERRNO{Errno->ERESTART} = 1 if Errno->can('ERESTART');

    # EWOULDBLOCK == EAGAIN on most platforms, but POSIX allows them to differ.
    %NONBLOCK_ERRNO = (EAGAIN() => 1);
    $NONBLOCK_ERRNO{Errno->EWOULDBLOCK} = 1 if Errno->can('EWOULDBLOCK');
}

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

    if (POSIX->can('SSIZE_MAX') && eval { POSIX::SSIZE_MAX() }) {
        *SSIZE_MAX = \&POSIX::SSIZE_MAX;
    }
    else {
        # POSIX guarantees SSIZE_MAX is at least 32767 (_POSIX_SSIZE_MAX).
        *SSIZE_MAX = sub() { 32767 };
    }

    {
        # Using the default pipe size as a read size is significantly faster
        # than a larger value on my test machine.
        my $read_size = min(SSIZE_MAX(), 65_536);
        *DEFAULT_READ_SIZE = sub() { $read_size };
    }

    my $can_thread = 1;
    $can_thread &&= $] >= 5.008001;
    $can_thread &&= $Config{'useithreads'};

    # Threads are broken on perl 5.10.0 built with gcc 4.8+
    if ($can_thread && $] == 5.010000 && $Config{'ccname'} eq 'gcc' && $Config{'gccversion'}) {
        my @parts = split /\./, $Config{'gccversion'};
        $can_thread = 0 if $parts[0] > 4 || ($parts[0] == 4 && $parts[1] >= 8);
    }

    $can_thread &&= !$INC{'Devel/Cover.pm'};

    if (!$can_thread) {
        *_get_tid = sub() { 0 };
    }
    elsif ($INC{'threads.pm'}) {
        *_get_tid = sub() { threads->tid() };
    }
    else {
        *_get_tid = sub() { $INC{'threads.pm'} ? threads->tid() : 0 };
    }

    if ($^O eq 'MSWin32') {
        local $@;
        eval { require Win32::API;     1 } or die "non-blocking on windows requires Win32::API please install it.\n$@";
        eval { require Win32API::File; 1 } or die "non-blocking on windows requires Win32API::File please install it.\n$@";
        *IS_WIN32 = sub() { 1 };
    }
    else {
        *IS_WIN32 = sub() { 0 };
    }
}

use constant READ_SIZE      => 'read_size';
use constant RH             => 'rh';
use constant WH             => 'wh';
use constant EOF            => 'eof';
use constant STATE          => 'state';
use constant OUT_BUFFER     => 'out_buffer';
use constant IN_BUFFER      => 'in_buffer';
use constant IN_BUFFER_SIZE => 'in_buffer_size';
use constant READ_BLOCKING  => 'read_blocking';
use constant WRITE_BLOCKING => 'write_blocking';
use constant BURST_PREFIX   => 'burst_prefix';
use constant BURST_POSTFIX  => 'burst_postfix';
use constant ADJUSTED_DSIZE => 'adjusted_dsize';
use constant MESSAGE_KEY    => 'message_key';
use constant MIXED_BUFFER   => 'mixed_buffer';
use constant DELIMITER_SIZE => 'delimiter_size';
use constant INVALID_STATE  => 'invalid_state';
use constant HIT_EPIPE      => 'hit_epipe';
use constant USE_IO_SELECT  => 'use_io_select';
use constant COMPRESSION                 => 'compression';
use constant COMPRESSION_LEVEL           => 'compression_level';
use constant COMPRESSION_DICTIONARY      => 'compression_dictionary';
use constant COMPRESSION_DICTIONARY_FILE => 'compression_dictionary_file';
use constant KEEP_COMPRESSED             => 'keep_compressed';
use constant COMPRESS_LARGE_ONLY         => 'compress_large_only';
use constant COMPRESSION_THRESHOLD       => 'compression_threshold';

# High bit of the 32-bit part size in a message header. Part sizes never exceed
# PIPE_BUF, so the bit is free; it marks the parts of a compressed message when
# compress_large_only is in use.
use constant SIZE_COMPRESSED_FLAG => 0x80000000;
use constant SIZE_MASK            => 0x7FFFFFFF;

sub wh  { shift->{+WH} }
sub rh  { shift->{+RH} }

sub throw_invalid {
    my $self = shift;
    $self->{+INVALID_STATE} //= @_ ? shift : 'Unknown Error';
    confess "Pipe is in an invalid state '$self->{+INVALID_STATE}'";
}

sub read_size {
    my $self = shift;
    ($self->{+READ_SIZE}) = @_ if @_;
    return $self->{+READ_SIZE} ||= DEFAULT_READ_SIZE();
}

sub use_io_select {
    my $self = shift;
    if (@_) {
        croak "IO::Select is not installed, cannot enable use_io_select" if $_[0] && !HAVE_IO_SELECT;
        $self->{+USE_IO_SELECT} = $_[0] ? 1 : 0;
        delete $self->{_select} unless $_[0];
    }
    return 0 unless HAVE_IO_SELECT;
    my $val = $self->{+USE_IO_SELECT};
    return defined($val) ? ($val ? 1 : 0) : IS_WIN32 ? 0 : 1;
}

sub compression                 { $_[0]->{+COMPRESSION} }
sub compression_level           { $_[0]->{+COMPRESSION_LEVEL} }
sub compression_dictionary      { $_[0]->{+COMPRESSION_DICTIONARY} }
sub compression_dictionary_file { $_[0]->{+COMPRESSION_DICTIONARY_FILE} }
sub keep_compressed             { $_[0]->{+KEEP_COMPRESSED} ? 1 : 0 }
# The threshold in effect (default included) while compress_large_only is on.
sub compression_threshold {
    my $self = shift;
    return undef unless $self->compress_large_only;
    return $self->_large_threshold;
}

sub compress_large_only {
    my $self = shift;
    return 1 if $self->{+COMPRESS_LARGE_ONLY} || defined $self->{+COMPRESSION_THRESHOLD};
    return 0;
}

sub fill_buffer {
    my $self = shift;

    $self->throw_invalid() if $self->{+INVALID_STATE};

    my $rh = $self->{+RH} or die "Not a read handle";

    return 0 if $self->{+EOF};

    $self->{+IN_BUFFER_SIZE} //= 0;

    my $to_read = $self->{+READ_SIZE} || DEFAULT_READ_SIZE();

    my $use_select = $self->use_io_select;

    if ($use_select) {
        my $sel = $self->{_select} //= IO::Select->new($rh);
        my $blocking = $self->{+READ_BLOCKING} // 1;
        my @ready = $sel->can_read($blocking ? undef : 0);
        return 0 unless @ready;
    }
    elsif (IS_WIN32 && defined($self->{+READ_BLOCKING}) && !$self->{+READ_BLOCKING}) {
        $to_read = min($self->_win32_pipe_ready(), $to_read);
    }

    return 0 unless $to_read;

    while (1) {
        my $rbuff = '';
        my $got = sysread($rh, $rbuff, $to_read);
        unless(defined $got) {
            return 0 if $NONBLOCK_ERRNO{0 + $!}; # NON-BLOCKING
            if ($RETRY_ERRNO{0 + $!}) {
                next unless $use_select; # retry on EINTR in fallback mode
                return 0;               # IO::Select handles EINTR
            }
            $self->throw_invalid("$!");
        }

        if ($got) {
            $self->{+IN_BUFFER} .= $rbuff;
            $self->{+IN_BUFFER_SIZE} += $got;
            return $got;
        }
        else {
            $self->{+EOF} = 1;
            return 0;
        }
    }

    return 0;
}

# Must forward %params: callers rely on eof_invalid to turn a truncated
# message at EOF into an exception instead of a clean-looking EOF.
sub _get_from_buffer  { my $self = shift; $self->_from_buffer(@_, remove => 1) }
sub _peek_from_buffer { shift->_from_buffer(@_) }

sub _from_buffer {
    my $self = shift;
    my ($size, %params) = @_;

    unless ($self->{+IN_BUFFER_SIZE} && $self->{+IN_BUFFER_SIZE} >= $size) {
        # Keep reading while reads return data: with a read_size smaller than
        # what is needed, one read is not enough, and a blocking caller would
        # otherwise get undef (which looks like EOF) in the middle of a
        # message. fill_buffer returns 0 at EOF and when a non-blocking read
        # finds nothing, which ends the loop.
        1 while ($self->{+IN_BUFFER_SIZE} // 0) < $size && $self->fill_buffer;
        unless($self->{+IN_BUFFER_SIZE} >= $size) {
            return unless $params{eof_invalid} && $self->{+EOF};
            $self->throw_invalid($params{eof_invalid});
        }
    }

    my $out;

    if ($params{remove}) {
        $self->{+IN_BUFFER_SIZE} -= $size;
        $out = substr($self->{+IN_BUFFER}, 0, $size, '');
    }
    else {
        $out = substr($self->{+IN_BUFFER}, 0, $size);
    }

    return $out;
}

sub _has_dict {
    return defined($_[0]->{+COMPRESSION_DICTIONARY})
        || defined($_[0]->{+COMPRESSION_DICTIONARY_FILE});
}

# NOTE: raw zstd dictionaries do not embed a dict-ID, so a mismatched peer
# dict will silently decode to garbage rather than fail. Both ends must agree
# on byte-identical dictionary content.
sub _build_cdict {
    my $self = shift;
    my $level = $self->{+COMPRESSION_LEVEL} // 3;
    require Compress::Zstd::CompressionDictionary;
    if (defined(my $path = $self->{+COMPRESSION_DICTIONARY_FILE})) {
        return Compress::Zstd::CompressionDictionary->new_from_file($path, $level);
    }
    return Compress::Zstd::CompressionDictionary->new($self->{+COMPRESSION_DICTIONARY}, $level);
}

sub _build_ddict {
    my $self = shift;
    require Compress::Zstd::DecompressionDictionary;
    if (defined(my $path = $self->{+COMPRESSION_DICTIONARY_FILE})) {
        return Compress::Zstd::DecompressionDictionary->new_from_file($path);
    }
    return Compress::Zstd::DecompressionDictionary->new($self->{+COMPRESSION_DICTIONARY});
}

sub _compress {
    my ($self, $data) = @_;
    if ($self->_has_dict) {
        require Compress::Zstd::CompressionContext;
        my $ctx   = $self->{_compression_ctx}   //= Compress::Zstd::CompressionContext->new;
        my $cdict = $self->{_compression_cdict} //= $self->_build_cdict;
        return $ctx->compress_using_dict($data, $cdict);
    }
    return Compress::Zstd::compress($data, $self->{+COMPRESSION_LEVEL} // 3);
}

sub _decompress {
    my ($self, $data) = @_;
    my $out;
    if ($self->_has_dict) {
        require Compress::Zstd::DecompressionContext;
        my $ctx   = $self->{_decompression_ctx}   //= Compress::Zstd::DecompressionContext->new;
        my $ddict = $self->{_decompression_ddict} //= $self->_build_ddict;
        $out = $ctx->decompress_using_dict($data, $ddict);
    }
    else {
        # A reader without compression configured can still receive messages
        # flagged as compressed by a compress_large_only writer.
        $self->throw_invalid("Received a compressed message but Compress::Zstd is not installed")
            unless eval { require Compress::Zstd; 1 };
        $out = Compress::Zstd::decompress($data);
    }
    $self->throw_invalid("zstd decompression failed") unless defined $out;
    return $out;
}

sub eof {
    my $self = shift;

    $self->throw_invalid() if $self->{+INVALID_STATE};

    return 0 if $self->fill_buffer;
    return $self->_drained;
}

# Same answer as eof() but without reading more data. Internal loops must use
# this: eof() pulls another read into in_buffer on every call, so calling it
# per pass drains the whole pipe into memory.
sub _drained {
    my $self = shift;

    return 0 unless $self->{+EOF};
    return 0 if $self->{+IN_BUFFER_SIZE};

    if (my $buffer = $self->{+MIXED_BUFFER}) {
        return 0 if defined($buffer->{lines}) && length($buffer->{lines});
        return 0 if defined($buffer->{burst}) && length($buffer->{burst});
    }

    return 1;
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

# compress_large_only (or a compression_threshold) turns compression on when
# no algorithm was given.
sub _implied_compression {
    my ($class, $params) = @_;
    return $params->{+COMPRESSION} if defined $params->{+COMPRESSION};
    return 'zstd' if $params->{+COMPRESS_LARGE_ONLY} || defined $params->{+COMPRESSION_THRESHOLD};
    return undef;
}

sub _check_params {
    my ($class, %params) = @_;
    croak "IO::Select is not installed, cannot enable use_io_select"
        if $params{+USE_IO_SELECT} && !HAVE_IO_SELECT;

    $params{+COMPRESSION} = $class->_implied_compression(\%params);

    if (defined(my $algo = $params{+COMPRESSION})) {
        croak "Unknown compression algorithm '$algo'" unless $algo eq 'zstd';
        croak "compression => 'zstd' requires Compress::Zstd"
            unless eval { require Compress::Zstd; 1 };
    }

    croak "compression_dictionary and compression_dictionary_file are mutually exclusive"
        if defined($params{+COMPRESSION_DICTIONARY}) && defined($params{+COMPRESSION_DICTIONARY_FILE});

    croak "compression_dictionary requires compression to be enabled"
        if (defined($params{+COMPRESSION_DICTIONARY}) || defined($params{+COMPRESSION_DICTIONARY_FILE}))
            && !defined($params{+COMPRESSION});

    croak "compression_threshold must be a non-negative integer"
        if defined($params{+COMPRESSION_THRESHOLD}) && $params{+COMPRESSION_THRESHOLD} !~ m/^\d+$/;
}

sub read_fifo {
    my $class = shift;
    my ($fifo, %params) = @_;

    $class->_check_params(%params);
    croak "File '$fifo' is not a pipe (-p check)" unless -p $fifo;

    open(my $fh, '+<', $fifo) or die "Could not open fifo ($fifo) for reading: $!";
    binmode($fh);

    return $class->_new_from_params(\%params, RH() => $fh);
}

sub write_fifo {
    my $class = shift;
    my ($fifo, %params) = @_;

    $class->_check_params(%params);
    croak "File '$fifo' is not a pipe (-p check)" unless -p $fifo;

    open(my $fh, '>', $fifo) or die "Could not open fifo ($fifo) for writing: $!";
    binmode($fh);

    return $class->_new_from_params(\%params, WH() => $fh);
}

sub from_fh {
    my $class = shift;

    # Mode is optional: from_fh($fh, %params) or from_fh($mode, $fh, %params).
    my $mode;
    $mode = shift if @_ && !ref($_[0]) && $MODE_TO_DIR{$_[0]};
    my $ifh = shift;
    my %params = @_;

    $class->_check_params(%params);

    croak "Filehandle is not a pipe (-p check)" unless -p $ifh;

    $mode //= $class->_fh_mode($ifh) // croak "Could not determine filehandle mode, please specify '>&' or '<&'";
    my $dir = $class->_mode_to_dir($mode) // croak "Invalid mode: $mode";

    open(my $fh, $mode, $ifh) or croak "Could not clone ($mode) filehandle: $!";
    binmode($fh);

    return $class->_new_from_params(\%params, $dir => $fh);
}

sub from_fd {
    my $class = shift;
    my ($mode, $fd, %params) = @_;

    $class->_check_params(%params);

    my $dir = $class->_mode_to_dir($mode) // croak "Invalid mode: $mode";
    open(my $fh, $mode, $fd) or croak "Could not open ($mode) fd$fd: $!";

    croak "Filehandle is not a pipe (-p check)" unless -p $fh;

    binmode($fh);
    return $class->_new_from_params(\%params, $dir => $fh);
}

sub _new_from_params {
    my ($class, $params, @handles) = @_;

    my $mixed = delete $params->{mixed_data_mode};

    # Remember when compression was switched on only because of
    # compress_large_only, so turning that off can switch it back off.
    unless (defined $params->{+COMPRESSION}) {
        my $algo = $class->_implied_compression($params);
        @{$params}{+COMPRESSION, '_compression_implied'} = ($algo, 1) if defined $algo;
    }

    my $self = bless({%$params, @handles}, $class);
    $self->set_mixed_data_mode() if $mixed;

    return $self;
}

sub new {
    my $class = shift;
    my (%params) = @_;

    $class->_check_params(%params);

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    return $class->_new_from_params(\%params, RH() => $rh, WH() => $wh);
}

sub pair {
    my $class = shift;
    my (%params) = @_;

    $class->_check_params(%params);

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not create pipe: $!";

    binmode($wh);
    binmode($rh);

    my $r = $class->_new_from_params({%params}, RH() => $rh);
    my $w = $class->_new_from_params({%params}, WH() => $wh);

    return ($r, $w);
}

sub set_mixed_data_mode {
    my $self = shift;

    $self->throw_invalid() if $self->{+INVALID_STATE};

    $self->read_blocking(0) if $self->{+RH};

    $self->{+BURST_PREFIX}  //= "\x0E";    # Shift out
    $self->{+BURST_POSTFIX} //= "\x0F";    # Shift in
    $self->{+MESSAGE_KEY}   //= "\x10";    # Data link escape
}

sub set_compression {
    my $self = shift;
    my ($algo, $level) = @_;

    # An explicit call makes the compression setting the caller's own.
    delete $self->{_compression_implied};

    if (!defined $algo) {
        delete $self->{+COMPRESSION};
        delete $self->{+COMPRESSION_LEVEL};
        delete $self->{_compression_ctx};
        delete $self->{_compression_cdict};
        delete $self->{_decompression_ctx};
        delete $self->{_decompression_ddict};
        delete $self->{_compress_cache};
        return;
    }

    croak "Unknown compression algorithm '$algo'" unless $algo eq 'zstd';
    croak "compression => 'zstd' requires Compress::Zstd"
        unless eval { require Compress::Zstd; 1 };

    $self->{+COMPRESSION}       = $algo;
    # Omitted $level preserves the previously set level; pass undef to
    # set_compression(undef) first if a full reset back to the default is desired.
    $self->{+COMPRESSION_LEVEL} = $level if defined $level;

    # Cached objects depend on level / dict; force rebuild.
    delete $self->{_compression_ctx};
    delete $self->{_compression_cdict};
    delete $self->{_decompression_ctx};
    delete $self->{_decompression_ddict};
    delete $self->{_compress_cache};

    return;
}

sub set_compression_dictionary {
    my ($self, $bytes) = @_;
    if (defined $bytes) {
        croak "compression_dictionary requires compression to be enabled"
            unless defined $self->{+COMPRESSION};
        $self->{+COMPRESSION_DICTIONARY} = $bytes;
        delete $self->{+COMPRESSION_DICTIONARY_FILE};
    }
    else {
        delete $self->{+COMPRESSION_DICTIONARY};
    }
    delete $self->{_compression_cdict};
    delete $self->{_decompression_ddict};
    delete $self->{_compress_cache};
    return;
}

sub set_compression_dictionary_file {
    my ($self, $path) = @_;
    if (defined $path) {
        croak "compression_dictionary requires compression to be enabled"
            unless defined $self->{+COMPRESSION};
        $self->{+COMPRESSION_DICTIONARY_FILE} = $path;
        delete $self->{+COMPRESSION_DICTIONARY};
    }
    else {
        delete $self->{+COMPRESSION_DICTIONARY_FILE};
    }
    delete $self->{_compression_cdict};
    delete $self->{_decompression_ddict};
    delete $self->{_compress_cache};
    return;
}

sub set_keep_compressed {
    my ($self, $val) = @_;
    $self->{+KEEP_COMPRESSED} = $val ? 1 : 0;
    return;
}

sub set_compress_large_only {
    my ($self, $val, $threshold) = @_;

    unless ($val) {
        delete $self->{+COMPRESS_LARGE_ONLY};
        delete $self->{+COMPRESSION_THRESHOLD};

        # Undo what turning it on did: if compression was only on because of
        # compress_large_only, switch it off; an explicit setting stays.
        $self->set_compression(undef) if $self->{_compression_implied};
        return;
    }

    croak "compression_threshold must be a non-negative integer"
        if defined($threshold) && $threshold !~ m/^\d+$/;

    # Turn compression on if it is not already (croaks without Compress::Zstd).
    unless (defined $self->{+COMPRESSION}) {
        $self->set_compression('zstd');
        $self->{_compression_implied} = 1;
    }

    $self->{+COMPRESS_LARGE_ONLY} = 1;
    if (defined $threshold) { $self->{+COMPRESSION_THRESHOLD} = $threshold }
    else                    { delete $self->{+COMPRESSION_THRESHOLD} }

    return;
}

# Messages longer than this are compressed under compress_large_only. The
# default is the largest payload that fits in one atomic part, so only messages
# that would otherwise be split are compressed.
sub _large_threshold {
    my $self = shift;
    return $self->{+COMPRESSION_THRESHOLD} // ($self->{+ADJUSTED_DSIZE} // $self->_adjusted_dsize);
}

# Bursts and legacy (unflagged) messages are compressed iff compression is on
# and compress_large_only is not.
sub _compress_all {
    my $self = shift;
    return 0 unless $self->{+COMPRESSION};
    return 0 if $self->{+COMPRESS_LARGE_ONLY} || defined $self->{+COMPRESSION_THRESHOLD};
    return 1;
}

# Length of the longest suffix of $buf that is a proper prefix of $delim: the
# bytes that may be the start of a delimiter split across reads. Anything else
# can be handed on right away.
sub _partial_suffix {
    my ($buf, $delim) = @_;
    for my $k (reverse 1 .. min(length($delim) - 1, length($buf))) {
        return $k if substr($buf, -$k) eq substr($delim, 0, $k);
    }
    return 0;
}

sub _mixed_message_result {
    my ($self, $message, $flagged) = @_;

    return (message => $message) unless $flagged || $self->_compress_all;

    my $decompressed = $self->_decompress($message);
    return (message => $decompressed, compressed => $message) if $self->{+KEEP_COMPRESSED};
    return (message => $decompressed);
}

sub get_line_burst_or_data {
    my $self = shift;
    my %params = @_;

    my $rh = $self->{+RH} // croak "Not a read handle";

    my $prefix  = $self->{+BURST_PREFIX}  // croak "missing 'burst_prefix', not in mixed_data_mode";
    my $postfix = $self->{+BURST_POSTFIX} // croak "missing 'burst_postfix', not in mixed_data_mode";
    my $key     = $self->{+MESSAGE_KEY}   // croak "missing 'message_key', not in mixed_data_mode";

    my $buffer = $self->{+MIXED_BUFFER} //= {
        lines      => '',
        burst      => '',
        in_burst   => 0,
        in_message => 0,
        strip_term => 0,
    };

    my $peek;

    while (1) {
        $self->throw_invalid('Incomplete message received before EOF')
            if $self->_drained && (keys(%{$self->{+STATE}->{buffers}}) || keys (%{$self->{+STATE}->{parts}}));

        if($buffer->{lines} || length($buffer->{lines})) {
            # Look for a complete line
            my ($line, $term);
            ($line, $term, $buffer->{lines}) = split /(\r?\n|\r\n?)/, $buffer->{lines}, 2;

            return (line => "${line}${term}") if $term;
            return (line => $line) if $self->{+EOF} && !$self->{+IN_BUFFER_SIZE} && defined($line) && length($line);

            $buffer->{lines} = $line;
            $peek = $line if $params{peek_line} && defined($line) && length($line);
        }

        if ($buffer->{in_message}) {
            my ($id, $message, $flagged) = $self->_extract_message(one_part_only => 1);

            unless(defined $id) {
                $self->throw_invalid('Incomplete burst data received before end of pipe')
                    if $self->{+EOF} && !$self->{+IN_BUFFER_SIZE};

                my $before = $self->{+IN_BUFFER_SIZE};
                $self->fill_buffer;
                next if $self->{+EOF} || $self->{+IN_BUFFER_SIZE} > $before;

                # Not EOF and no new bytes arrived: another pass cannot make
                # progress. Return empty so a non-blocking caller can wait and
                # retry instead of spinning inside this call.
                return;
            }

            $buffer->{strip_term}++;
            $buffer->{in_message} = 0;
            return $self->_mixed_message_result($message, $flagged) if defined $message;
        }

        if ($buffer->{strip_term}) {
            my $term = $self->_get_from_buffer(length($postfix), eof_invalid => 'EOF before message terminator') // return;

            $self->throw_invalid("No message terminator") unless $term eq $postfix;
            $buffer->{strip_term}--;
        }

        if ($buffer->{in_burst}) {
            # undef here means a non-blocking read found nothing (EOF throws);
            # looping again cannot make progress.
            my $first = $self->_peek_from_buffer(1, eof_invalid => 'Incomplete burst data received before end of pipe');
            unless (defined $first) {
                return (peek => $peek) if $peek;
                return;
            }

            # Only the first byte of a burst can be the message key; later
            # reads continuing a burst are data.
            if ($first eq $key && !length($buffer->{burst} // '')) {
                # Fast path: the whole part (key, header, payload, postfix) is
                # already buffered, so take it in one step.
                if (my @part = $self->_take_part(length($key), $postfix)) {
                    $buffer->{in_burst} = 0;
                    my ($message, $flagged) = $self->_assemble(@part);
                    next unless defined $message;
                    return $self->_mixed_message_result($message, $flagged);
                }

                $self->_get_from_buffer(1); # Strip the key
                $buffer->{in_message} = 1;
                $buffer->{in_burst} = 0;
                next;
            }

            # Consume with index + 4-arg substr: chopping the front of a
            # string is O(1) in perl, while split would copy the remainder of
            # the buffer every time, making a large buffer quadratic.
            $buffer->{burst} //= '';
            my $term;
            my $at = index($self->{+IN_BUFFER}, $postfix);
            if ($at < 0) {
                # Keep a possible partial postfix at the end of the buffer so
                # a multi-byte postfix split across reads is still found.
                my $keep = _partial_suffix($self->{+IN_BUFFER}, $postfix);
                my $take = length($self->{+IN_BUFFER}) - $keep;
                $buffer->{burst} .= substr($self->{+IN_BUFFER}, 0, $take, '') if $take;
            }
            else {
                $buffer->{burst} .= substr($self->{+IN_BUFFER}, 0, $at, '') if $at;
                $term = substr($self->{+IN_BUFFER}, 0, length($postfix), '');
            }

            if (defined $term) {
                $self->{+IN_BUFFER_SIZE} = length($self->{+IN_BUFFER});
                $buffer->{in_burst} = 0;
                my $compressed = delete $buffer->{burst};
                if ($self->_compress_all) {
                    my $decompressed = $self->_decompress($compressed);
                    return (burst => $decompressed, compressed => $compressed)
                        if $self->{+KEEP_COMPRESSED};
                    return (burst => $decompressed);
                }
                return (burst => $compressed);
            }

            # The rest of the burst is not here yet. Read more and stay in the
            # burst; falling through would treat the next read as line data.
            $self->{+IN_BUFFER_SIZE} = length($self->{+IN_BUFFER});
            $self->throw_invalid('Incomplete burst data received before end of pipe') if $self->{+EOF};
            next if $self->fill_buffer;
            $self->throw_invalid('Incomplete burst data received before end of pipe') if $self->{+EOF};
            return (peek => $peek) if $peek;
            return;
        }

        # A held partial prefix (see below) counts as an empty buffer: it
        # cannot be classified until more data arrives.
        my $held = $buffer->{held_prefix} && $self->{+IN_BUFFER_SIZE};
        unless (($self->{+IN_BUFFER_SIZE} && !$held) || $self->fill_buffer()) {
            return (peek => $peek) if $peek && !$self->{+EOF};

            return unless $self->{+EOF};

            if ($held) {
                # No more data is coming, so the held bytes are line data.
                $buffer->{lines} .= $self->{+IN_BUFFER};
                $self->{+IN_BUFFER}      = '';
                $self->{+IN_BUFFER_SIZE} = 0;
                $buffer->{held_prefix}   = 0;
                next;
            }

            # Do at least one more iteration after EOF
            return if $buffer->{+EOF}++;

            # But do not try to split the empty buffer
            next;
        }
        $buffer->{held_prefix} = 0;

        # Look for the start of a burst, anything before a burst is line data
        my $at = index($self->{+IN_BUFFER}, $prefix);
        if ($at < 0) {
            # Hold back a possible partial prefix at the end of the buffer so
            # a multi-byte prefix split across reads is still found.
            my $keep = _partial_suffix($self->{+IN_BUFFER}, $prefix);
            my $take = length($self->{+IN_BUFFER}) - $keep;
            $buffer->{lines} .= substr($self->{+IN_BUFFER}, 0, $take, '') if $take;
            $self->{+IN_BUFFER_SIZE} = length($self->{+IN_BUFFER});
            $buffer->{held_prefix}   = $self->{+IN_BUFFER_SIZE} ? 1 : 0;
        }
        else {
            $buffer->{lines} .= substr($self->{+IN_BUFFER}, 0, $at, '') if $at;
            $buffer->{in_burst} = substr($self->{+IN_BUFFER}, 0, length($prefix), '');
            $self->{+IN_BUFFER_SIZE} = length($self->{+IN_BUFFER});
        }
    }
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

    $self->{+EOF} = 1 if $ret == 0;

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

sub read_blocking {
    my $self = shift;
    my $rh   = $self->{+RH} or croak "Not a reader";

    ($self->{+READ_BLOCKING}) = @_ if @_;

    unless (IS_WIN32) {
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
        $self->_win32_set_pipe_state(@_) if @_;
    }
    else {
        my $flags = fcntl($wh, &Fcntl::F_GETFL, 0);    # Get the current flags
        die $! unless defined $flags;
        if   ($val) { $flags &= ~&Fcntl::O_NONBLOCK }  # Clear O_NONBLOCK
        else        { $flags |= &Fcntl::O_NONBLOCK }   # Set O_NONBLOCK
        fcntl($wh, &Fcntl::F_SETFL, $flags) || die $!;
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

    # Force numeric: fcntl(F_SETPIPE_SZ, $string) is interpreted as
    # buffer-mode and silently fails with EINVAL.
    fcntl($fh, Fcntl::F_SETPIPE_SZ(), $size + 0);
}

my $ONE_MB = 1 * 1024 * 1024;

sub max_size {
    return $ONE_MB unless -e '/proc/sys/fs/pipe-max-size';

    open(my $max, '<', '/proc/sys/fs/pipe-max-size') or return $ONE_MB;
    chomp(my $val = <$max>);
    close($max);
    # Force numeric. <$max> returns a string; passing it to
    # fcntl(F_SETPIPE_SZ) directly triggers the same EINVAL bug
    # resize() guards against. Numify here so any caller of
    # max_size() that hands the result to fcntl gets an int.
    return ($val + 0) || $ONE_MB;
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

    $self->_flush_before_close;
    close(delete $self->{+WH});
    return 1;
}

# Buffered bursts from non-blocking writes must not be silently dropped when
# the write handle goes away (DESTROY would also croak trying to flush them
# without a handle).
sub _flush_before_close {
    my $self = shift;
    return if $self->{+HIT_EPIPE} || $self->{+INVALID_STATE};
    $self->flush(blocking => 1) if $self->pending_output;
}

sub close {
    my $self = shift;
    if ($self->{+WH}) {
        $self->_flush_before_close;
        close(delete $self->{+WH});
    }
    close(delete $self->{+RH}) if $self->{+RH};
    return;
}

my $psize = 16; # 32bit pid, 32bit tid, 32 bit size, 32 bit int part id;
my $dsize = PIPE_BUF - $psize;

sub delimiter_size {
    return $_[0]->{+DELIMITER_SIZE} if defined $_[0]->{+DELIMITER_SIZE};
    return $_[0]->{+DELIMITER_SIZE} //= bytes::length($_[0]->{+BURST_PREFIX} // '') + bytes::length($_[0]->{+BURST_POSTFIX} // '');
}

# The typical fits_in_burst() then write_burst() sequence would compress the
# same payload twice; remember the last result.
sub _compress_cached {
    my ($self, $data) = @_;

    my $cache = $self->{_compress_cache};
    return $cache->[1] if $cache && $cache->[0] eq $data;

    my $out = $self->_compress($data);
    $self->{_compress_cache} = [$data, $out];
    return $out;
}

sub fits_in_burst {
    my $self = shift;
    my ($data) = @_;

    $data = $self->_compress_cached($data) if $self->_compress_all;

    my $size = bytes::length($data) + ($self->{+DELIMITER_SIZE} // $self->delimiter_size);
    return undef unless $size <= PIPE_BUF;

    return $size;
}

sub write_burst {
    my $self = shift;
    my ($data) = @_;

    $data = $self->_compress_cached($data) if $self->_compress_all;

    my $size = bytes::length($data) + ($self->{+DELIMITER_SIZE} // $self->delimiter_size);
    return undef unless $size <= PIPE_BUF;

    push @{$self->{+OUT_BUFFER} //= []} => [$data, $size];
    $self->flush();

    return 1;
}

sub DESTROY {
    my $self = shift;
    local ($., $@, $!, $^E, $?);
    return if $self->{+HIT_EPIPE} || $self->{+INVALID_STATE};
    $self->flush(blocking => 1) if $self->{+WH} && $self->pending_output;
}

sub pending_output {
    my $self = shift;
    my $buffer = $self->{+OUT_BUFFER} or return 0;
    return 0 unless @$buffer;
    return 1;
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

    croak "Disconnected pipe" if $self->{+HIT_EPIPE};

    my $prefix  = $self->{+BURST_PREFIX}  // '';
    my $postfix = $self->{+BURST_POSTFIX} // '';

    $data = "${prefix}${data}${postfix}" if length($prefix) || length($postfix);

    my $wrote;
    SWRITE: {
        $wrote = syswrite($wh, $data, $size);

        # $! is only meaningful when syswrite fails.
        unless (defined $wrote) {
            if ($! == EPIPE || (IS_WIN32 && $! == 22)) {
                $self->{+HIT_EPIPE} = 1;
                delete $self->{+OUT_BUFFER};
                croak "Disconnected pipe";
            }
            return undef if $NONBLOCK_ERRNO{0 + $!} || (IS_WIN32 && $! == 28);    # NON-BLOCKING
            redo SWRITE if $RETRY_ERRNO{0 + $!};
            $self->throw_invalid("syswrite failed: $!");
        }

        redo SWRITE unless $wrote;
        last SWRITE if $wrote == $size;
        die "partial write: $wrote vs $size: $!";
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

sub write_message {
    my $self = shift;
    my ($data) = @_;

    my $adjusted_dsize = $self->{+ADJUSTED_DSIZE} // $self->_adjusted_dsize;

    my $flag = 0;
    if ($self->{+COMPRESSION}) {
        if ($self->_compress_all) {
            $data = $self->_compress($data);
        }
        elsif (bytes::length($data) > $self->_large_threshold) {
            # Only keep the compressed form when it actually saves space.
            my $compressed = $self->_compress($data);
            if (bytes::length($compressed) < bytes::length($data)) {
                $data = $compressed;
                $flag = SIZE_COMPRESSED_FLAG;
            }
        }
    }

    my $tid         = _get_tid();
    my $message_key = $self->{+MESSAGE_KEY} // '';
    my $dtotal      = bytes::length($data);

    my $parts = int($dtotal / $adjusted_dsize);
    $parts++ if $dtotal % $adjusted_dsize;

    my $id = $parts - 1;

    # Unwinding the loop for a 1-part message for micro-optimization
    if ($parts == 1) {
        my $bytes = $data;
        my $size  = $dtotal;
        my $out   = $message_key . pack("l2L2", $$, $tid, $id--, $size | $flag) . $bytes;

        my $out_size = $dtotal + ($self->{+DELIMITER_SIZE} // $self->delimiter_size) + $psize + ($message_key ? 1 : 0);

        push @{$self->{+OUT_BUFFER} //= []} => [$out, $out_size];
    }
    else {
        for (my $part = 0; $part < $parts; $part++) {
            my $bytes = bytes::substr($data, $part * $adjusted_dsize, $adjusted_dsize);
            my $size  = bytes::length($bytes);

            my $out = $message_key . pack("l2L2", $$, $tid, $id--, $size | $flag) . $bytes;

            my $out_size = bytes::length($out) + ($self->{+DELIMITER_SIZE} // $self->delimiter_size);
            push @{$self->{+OUT_BUFFER} //= []} => [$out, $out_size];
        }
    }

    $self->flush();
    return $parts;
}

# Fast path: take one whole message part off the front of the buffer in a
# single step, but only if all of it is already there:
#   $lead bytes (the message key in mixed mode), the 16 byte header, the
#   payload, then $trail (the burst postfix in mixed mode).
# Returns ($pid, $tid, $id, $flagged, $data), or nothing (buffer untouched)
# when the part is incomplete or malformed; the slower step-by-step path then
# handles it, including partial reads and EOF errors.
sub _take_part {
    my ($self, $lead, $trail) = @_;

    my $have = $self->{+IN_BUFFER_SIZE} or return;
    return if $have < $lead + $psize;

    my ($pid, $tid, $id, $size) = $lead
        ? unpack("x$lead l2L2", $self->{+IN_BUFFER})
        : unpack('l2L2', $self->{+IN_BUFFER});
    my $flagged = $size & SIZE_COMPRESSED_FLAG ? 1 : 0;
    $size &= SIZE_MASK;

    my $tlen  = defined($trail) ? length($trail) : 0;
    my $total = $lead + $psize + $size + $tlen;
    return if $have < $total;
    return if $tlen && substr($self->{+IN_BUFFER}, $total - $tlen, $tlen) ne $trail;

    substr($self->{+IN_BUFFER}, 0, $lead + $psize, '');
    my $data = substr($self->{+IN_BUFFER}, 0, $size, '');
    substr($self->{+IN_BUFFER}, 0, $tlen, '') if $tlen;
    $self->{+IN_BUFFER_SIZE} = $have - $total;

    return ($pid, $tid, $id, $flagged, $data);
}

# Add one part to the reassembly state. Returns ($message, $flagged) once the
# final part (id 0) arrives, nothing before that. A single-part message with no
# earlier parts pending skips the bookkeeping entirely.
sub _assemble {
    my ($self, $pid, $tid, $id, $flagged, $data) = @_;

    my $state = $self->{+STATE} //= {};
    my $tag   = "$pid:$tid";

    return ($data, $flagged) if $id == 0 && !($state->{buffers} && exists $state->{buffers}->{$tag});

    push @{$state->{parts}->{$tag} //= []} => $id;
    $state->{buffers}->{$tag} .= $data;
    return unless $id == 0;

    delete $state->{parts}->{$tag};
    return (delete($state->{buffers}->{$tag}), $flagged);
}

sub read_message {
    my $self = shift;
    my %params = @_;

    my ($id, $out, $flagged) = $self->_extract_message(%params);

    return unless defined $id;

    return $out unless $flagged || $self->_compress_all;

    if ($params{debug}) {
        my $compressed = $out->{message};
        $out->{message} = $self->_decompress($compressed);
        $out->{compressed} = $compressed if $self->{+KEEP_COMPRESSED};
        return $out;
    }

    my $compressed   = $out;
    my $decompressed = $self->_decompress($compressed);

    return ($decompressed, $compressed) if $self->{+KEEP_COMPRESSED} && wantarray;
    return $decompressed;
}

sub _extract_message {
    my $self   = shift;
    my %params = @_;

    my $state = $self->{+STATE} //= {};

    while (1) {
        # Whole part already buffered: take it in one step. (debug wants the
        # per-message part list, so it always uses the step-by-step path.)
        if (!$state->{key} && !$params{debug} && (my @part = $self->_take_part(0))) {
            my $id = $part[2];
            my ($message, $flagged) = $self->_assemble(@part);
            return ($id, $message, $flagged) if $id == 0;
            return ($id, undef) if $params{one_part_only};
            next;
        }

        unless ($state->{key}) {
            my $key_bytes = $self->_get_from_buffer($psize);
            unless (defined($key_bytes) && length($key_bytes)) {
                # Leftover bytes smaller than a header at EOF mean a writer
                # died mid-message; a plain return here would look like a
                # clean EOF and silently drop data.
                $self->throw_invalid("EOF inside message header (truncated message)")
                    if $self->{+EOF} && $self->{+IN_BUFFER_SIZE};
                return;
            }

            my %key;
            @key{qw/pid tid id size/} = unpack('l2L2', $key_bytes);
            $key{compressed} = $key{size} & SIZE_COMPRESSED_FLAG ? 1 : 0;
            $key{size} &= SIZE_MASK;
            $state->{key} = \%key;
        }

        my $key = $state->{key};

        my $data = $self->_get_from_buffer($key->{size}, eof_invalid => "EOF before end of message") // return;

        my $id   = $key->{id};
        my $tag  = join ':' => @{$key}{qw/pid tid/};
        push @{$state->{parts}->{$tag} //= []} => $id;
        # Append in place; rebuilding the string per part is quadratic in
        # message size.
        $state->{buffers}->{$tag} .= $data;

        delete $state->{key};

        unless ($id == 0) {
            return ($id, undef) if $params{one_part_only};
            next;
        }

        my $message = delete $state->{buffers}->{$tag};
        my $parts   = delete $state->{parts}->{$tag};

        return ($id, $message, $key->{compressed}) unless $params{debug};

        return (
            $id,
            {
                message => $message,
                parts   => $parts,
                pid     => $key->{pid},
                tid     => $key->{tid},
            },
            $key->{compressed},
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
slightly smaller than the PIPE_BUF limit. Each section is sent as 1 atomic
chunk with a 16 byte header consisting of four 32-bit fields: the process id it
came from, the thread id it came from, a chunk ID (in descending order, so if
there are 3 chunks the first will have id 2, the second 1, and the final chunk
is always 0 allowing a flush as it knows it is done) and the length of the data
section to follow.

B<NOTE:> Payloads are byte strings. If you have a wide-character (unicode)
string, encode it (e.g. with L<Encode/encode>) before passing it to
C<write_message()> or C<write_burst()>; decode on the read side.

On the receiving end this module will read chunks and re-assemble them based on
the header data. So the reader will always get complete messages. Note that
message order is not guaranteed when messages are sent from multiple processes
or threads. Though all messages from any given thread/process should be in
order.

=head1 SYNOPSIS

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

    # For simplicity
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
        "Got all 3 long messages, not mangled or mixed, order not guaranteed"
    );

    done_testing;

Optional Zstd compression, only for messages too big for one atomic write
(the recommended way to use compression):

    my ($r, $w) = Atomic::Pipe->pair(compress_large_only => 1);

    # Fits in one atomic part: sent as-is, no compression cost.
    $w->write_message($small_payload);

    # Larger than one atomic part (4080 bytes on Linux by default): compressed
    # first, then split only if it is still too big.
    $w->write_message($big_payload);

    my $msg = $r->read_message;    # decompressed transparently when needed

Pass C<< compression_threshold => $bytes >> to use a different cut-off.

Or compress every burst and message (both ends must agree):

    my ($r, $w) = Atomic::Pipe->pair(compression => 'zstd');

See L</COMPRESSION> for details and options.

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

    # Any number of newlines is fine the message will send/receive as a whole.
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

=head1 COMPRESSION

C<Atomic::Pipe> can transparently compress B<bursts> and B<messages> (including
in mixed-data mode) with Zstandard. Plain C<print $wh ...> traffic is B<not>
compressed. Both ends of the pipe must be configured the same way; mismatch
produces protocol errors (or, in the case of mismatched dictionaries, silent
corruption -- see L</"Custom dictionary"> below).

Requires L<Compress::Zstd> (a soft / recommended dependency, loaded only when
compression is enabled).

=head2 Constructor options

All constructors (C<new>, C<pair>, C<from_fh>, C<from_fd>, C<read_fifo>,
C<write_fifo>) accept:

=over 4

=item compression => 'zstd'

Enable Zstd compression. Currently C<'zstd'> is the only supported algorithm;
any other value croaks at construction.

=item compression_level => $level

Zstd compression level, defaults to 3. Only meaningful when C<compression> is
enabled.

=item compression_dictionary => $bytes

Optional shared Zstd dictionary, supplied as raw bytes. Both ends must use the
same dictionary content. Mutually exclusive with C<compression_dictionary_file>.

=item compression_dictionary_file => $path

Same as C<compression_dictionary> but loaded from a file via
L<Compress::Zstd::CompressionDictionary/new_from_file>. The file is read on
demand.

=item keep_compressed => $bool

When set together with C<compression>, reads expose the on-wire compressed
bytes alongside the decompressed payload. See L<< read_message|/"$msg = $p->read_message" >> and
L<< get_line_burst_or_data|/"($type, $data) = $r->get_line_burst_or_data()" >> for the exact return-shape changes. Has no effect
without C<compression>.

Under L</compress_large_only> only messages that were actually compressed
report a compressed form; messages sent plain return just the payload.

=item compress_large_only => $bool

Compress only messages too big for one atomic part, and send the rest plain.
Turns on C<< compression => 'zstd' >> when no C<compression> is given, so this
one option is all most users need. See L</"Compressing only large messages">.

=item compression_threshold => $bytes

B<Optional.> Messages longer than C<$bytes> are compressed.

B<Default:> the largest payload that fits in one atomic part, C<PIPE_BUF>
minus framing. That is B<4080 bytes> on Linux (4077 in mixed-data mode), so
exactly the messages that would otherwise be split get compressed.

C<0> compresses every message that compression makes smaller. Unlike plain
C<compression>, this still uses the flagged format, so incompressible
messages go out as-is.

Setting this also turns on C<compress_large_only> (and compression). The
L</compression_threshold> accessor reports the threshold in use.

=back

=head2 Compressing only large messages

With plain C<compression> every burst and message is compressed. For small
messages that is pure CPU cost: they already fit in one atomic write, and
decompressing on a single reader is slower than reading them as-is.
C<compress_large_only> compresses a message only when it is longer than
L</compression_threshold>, and only keeps the compressed form when it is
actually smaller (already-compressed or random payloads go out plain).

    my ($r, $w) = Atomic::Pipe->pair(compress_large_only => 1);

That is the whole setup. It turns on zstd and uses the default threshold:

=over 4

=item *

A message that fits in one atomic part (up to 4080 bytes on Linux, 4077 in
mixed-data mode) is sent as-is.

=item *

A larger message is compressed first, then split into parts only if it is
still too big for one.

=item *

If compressing does not make it smaller, it is sent as-is (and split as
usual).

=back

To use a different cut-off:

    my ($r, $w) = Atomic::Pipe->pair(compression_threshold => 16_384);

Each compressed message is marked by the high bit of the part-size field in
its headers, so the reader knows which messages to decompress. Consequences:

=over 4

=item *

B<Mixing versions is not supported.> Both ends must run this version or
later. An older reader takes the flagged size field as a ~2 GB part: on a
plain pipe it stalls until EOF and then throws C<EOF before end of message>,
and on a FIFO that stays open it hangs forever with no error. Atomic::Pipe is
almost always used between forked processes running the same code, so this
should not come up; just don't enable C<compress_large_only> on a writer that
older readers consume.

=item *

Configure C<compress_large_only> on the reader too (or leave compression off
there, see the next point). A reader with plain C<compression> and no
C<compress_large_only> still tries to decompress every unflagged message.

=item *

A reader without C<compression> configured still decompresses flagged
messages, as long as L<Compress::Zstd> is installed. A custom dictionary must
still be configured on both ends.

=item *

Bursts (L<< write_burst|/"$undef_or_true = $p->write_burst($data)" >>) are never compressed in this mode, and the reader
does not try to decompress them.

=item *

With C<keep_compressed>, only messages that were sent compressed report a
compressed form.

=back

Plain C<compression> without C<compress_large_only> keeps the original wire
format, so it stays compatible with older versions.

=head2 Custom dictionary

Custom Zstd dictionaries can dramatically reduce frame size for small,
repetitive payloads. Either form (bytes or file) may be supplied at
construction or via L<< set_compression_dictionary|/"$p->set_compression_dictionary($bytes)" >> /
L<< set_compression_dictionary_file|/"$p->set_compression_dictionary_file($path)" >>.

B<Caveat:> raw zstd dictionaries do not embed a dict-ID. As a result a
B<mismatched> peer dictionary will silently decode to garbage rather than
fail. (Hard frame corruption -- truncated or invalid frames -- still raises
fatally.) Both ends must agree on byte-identical dictionary content.

=head2 Performance

Compression trades CPU for wire size. Whether it is also faster depends on
where the bottleneck is:

=over 4

=item *

B<Small messages> (that already fit in one atomic part) are always faster
plain. Compressing them only adds work on both ends.

=item *

B<Large messages with one writer> are also faster plain: the reader does the
same work either way, and decompression is extra.

=item *

B<Large messages from many writers into one reader> can be faster compressed
in mixed-data mode, where each part costs the reader more. Compression runs in
parallel in the writers, decompression is cheap, and the reader handles fewer
parts. This is the case L</compress_large_only> is for. With plain
C<read_message> the reader is fast enough that plain still wins.

=back

Versions before 0.033 had a reader bug that made reading large streams
quadratic, especially in mixed-data mode. Compression shrank the stream and so
hid most of it, which is why older versions of this documentation reported
compression as up to ~1000x faster. That advice no longer applies.

The kernel pipe buffer size (see L<< resize|/"$p->resize($bytes)" >>) has little effect on throughput.

=head3 Benchmark: streaming JSON objects

From C<bench/zstd_compression.pl> in the distribution: one writer, one reader,
mixed-data mode, 100 MB of synthetic JSON objects of 187 .. 10000 bytes
(average ~5.1 KB, so most are larger than C<PIPE_BUF>), 1 MB pipe:

  mode        raw MB/s   wire MB    ratio
  plain         530.70    100.00       -
  L-3           276.39     35.61    2.81x
  L1            240.18     30.56    3.27x
  L3 (def)      208.35     30.25    3.31x
  large-only    244.90     40.67    2.46x

("large-only" is C<compress_large_only> at the default threshold and level.)

A separate run with 1 and 8 writers into one reader, MB/s. Large messages are
~1.6 MB:

  large messages        plain    zstd   large-only
  1 writer, mixed         883     482          503
  1 writer, read_msg     1337     530          520
  8 writers, mixed        878    1143         1112
  8 writers, read_msg    1339    1148         1171

Small messages are ~1.2 KB, so large-only sends them all plain:

  small messages        plain    zstd   large-only
  1 writer, mixed         359     121          335
  1 writer, read_msg      555     129          477
  8 writers, mixed        344     119          334
  8 writers, read_msg     649     140          587

=head3 Practical guidance

=over 4

=item *

Leave compression off unless wire size matters, or many writers feed one
reader with large messages in mixed-data mode. With one writer, compression
of any kind is slower: about half the speed for large messages.

=item *

A reader that is slowed down by other work (for example, it writes every
message to a database) gains nothing from compression either; the pipe is not
its bottleneck.

=item *

If you do enable it, prefer L</compress_large_only> over plain
C<compression>: small messages go out plain, so they keep their speed, and
large ones are compressed. With many writers it stays within about 15% of the
faster of plain and full compression in the runs above.

=item *

For JSON-like payloads, B<level 1> or the default B<level 3> are good
starting points. Levels above ~7 buy single-digit-percent ratio gains for
multi-x CPU cost; in an IPC path they are rarely worth it.

=item *

A custom dictionary (L</"Custom dictionary">) helps most when payloads are
small and share structure -- e.g. identical JSON keys across every message.

=back

These results depend heavily on payload entropy, CPU and topology. Re-run
C<bench/zstd_compression.pl> against a representative slice of your own data
before deciding.

=head1 METHODS

=head2 CLASS METHODS

=over 4

=item $bytes = Atomic::Pipe->PIPE_BUF

Get the maximum number of bytes for an atomic write to a pipe.

=item $bool = Atomic::Pipe->HAVE_IO_SELECT

True if L<IO::Select> is available on this system. When available, it is used by
default in C<fill_buffer()> to efficiently wait for pipe readability instead of
relying on blocking C<sysread()> with an EINTR retry loop.

=item ($r, $w) = Atomic::Pipe->pair

=item ($r, $w) = Atomic::Pipe->pair(%params)

Create a pipe, returns a list consisting of a reader and a writer.

All constructors accept the same optional C<%params>: the compression options
documented in L</COMPRESSION>, and C<< mixed_data_mode => 1 >> (see
L</"MIXED DATA MODE">).

=item $p = Atomic::Pipe->new

=item $p = Atomic::Pipe->new(%params)

If you really must have a C<new()> method it is here for you to abuse. The
returned pipe has both handles, it is your job to then turn it into 2 clones
one with the reader and one with the writer. It is also your job to make sure
you do not have too many handles floating around preventing an EOF.

=item $r = Atomic::Pipe->read_fifo($FIFO_PATH, %params)

=item $w = Atomic::Pipe->write_fifo($FIFO_PATH, %params)

These 2 constructors let you connect to a FIFO by filesystem path.

The interface difference (read_fifo and write_fifo vs specifying a mode) is
because the modes to use for fifo's are not obvious (C<< '+<' >> for reading).

B<NOTE:> THERE IS NO EOF for the read-end in the process that created the fifo.
You need to figure out when the last message is received on your own somehow.
If you use blocking reads in a loop with no loop exit condition then the loop
will never end even after all writers are gone.

=item $p = Atomic::Pipe->from_fh($fh, %params)

=item $p = Atomic::Pipe->from_fh($mode, $fh, %params)

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

=item $p = Atomic::Pipe->from_fd($mode, $fd, %params)

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

When C<compression> and C<keep_compressed> are both enabled, list-context calls
additionally return the raw on-wire compressed bytes:

    my ($message, $compressed) = $p->read_message;

In C<< debug => 1 >> mode the returned hashref gains a C<compressed> key
holding the raw compressed bytes. Scalar-context calls always return just the
decompressed message, regardless of C<keep_compressed>.

Under L</compress_large_only> only messages that were sent compressed carry
the extra value; plain messages return just the message.

=item $p->blocking($bool)

=item $bool = $p->blocking

Get/Set blocking status. This works on read and write handles. On writers this
will write as many chunks/bursts as it can, then buffer any remaining until
your next write_message(), write_burst(), or flush(), at which point it will
write as much as it can again. If the instance is garbage collected with
chunks/bursts in the buffer it will block until all can be written.

=item $bool = $p->pending_output

True if the pipe is a non-blocking writer and there is pending output waiting
for a flush (and for the pipe to have room for the new data).

=item $w->flush()

Write any buffered items. This is only useful on writers that are in
non-blocking mode, it is a no-op everywhere else.

=item $bool = $r->eof()

True if all writers are closed, and the buffers do not contain any usable data.

Usable data means raw data that has yet to be processed, complete messages, or
complete data bursts. Any of these can still be retrieved using
C<read_message()>, or C<get_line_burst_or_data()>.

=item $p->close

Close this end of the pipe (or both ends if this is not yet split into
reader/writer pairs).

If the writer has output buffered by non-blocking writes, it is flushed
(blocking) before the write handle is closed so the data is not lost. The
flush is skipped if the pipe already hit C<EPIPE> or is in an invalid state.

=item $undef_or_bytes = $p->fits_in_burst($data)

This will return C<undef> if the data DOES NOT fit in a burst. This will return
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
of 512 bytes on systems that support atomic pipes according to POSIX).

=item $fh = $p->rh

=item $fh = $p->wh

Get the read or write handles.

=item $read_size = $p->read_size()

=item $p->read_size($read_size)

Get/set the read size. This is how much data to ATTEMPT to read each time
C<fill_buffer()> is called. The default is 65,536 which is the default pipe
size on linux, though the value is hardcoded currently.

=item $bool = $p->use_io_select

=item $p->use_io_select($bool)

Get/Set whether this pipe instance uses L<IO::Select> for readability checks in
C<fill_buffer()>. When true (and IO::Select is available), C<fill_buffer()> uses
C<< IO::Select->can_read() >> to wait for data. When false, it falls back to a
blocking C<sysread()> with an EINTR retry loop.

Defaults to true if IO::Select is installed (false on Windows, where
C<PeekNamedPipe> is used instead). Can also be passed as a constructor
parameter, e.g. C<< Atomic::Pipe->pair(use_io_select => 0) >>.

=item $bytes = $p->fill_buffer

Read a chunk of data from the pipe and store it in the internal buffer. Bytes
read are returned. This is only useful if you want to pull data out of the pipe
(maybe to unblock the writer?) but do not want to process any of the data yet.

This is automatically called as needed by other methods, usually you do not
need to use it directly.

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

Maximum size the pipe buffer can be resized to. On Linux this is read from
C</proc/sys/fs/pipe-max-size>; on systems where it cannot be determined this
falls back to a conservative 1MB.

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

This turns the object into a reader-only. Note that if you have no
writer-copies then effectively makes it impossible to write to the pipe as you
cannot get a writer anymore.

Any output buffered by non-blocking writes is flushed (blocking) before the
write handle is closed.

=item $p->writer

This turns the object into a writer-only. Note that if you have no
reader-copies then effectively makes it impossible to read from the pipe as you
cannot get a reader anymore.

=back

=head3 MIXED DATA MODE METHODS

=over 4

=item $p->set_mixed_data_mode

Enable mixed-data mode. Also makes read-side non-blocking.

=item ($type, $data) = $r->get_line_burst_or_data()

=item ($type, $data) = $r->get_line_burst_or_data(peek_line => 1)

Get a line, a burst, or a message from the pipe. Always non-blocking, will
return C<< (undef, undef) >> if no complete line/burst/message is ready.

$type will be one of: C<undef>, C<'line'>, C<'burst'>, C<'message'>, or C<'peek'>.

$data will either be C<undef>, or a complete line, burst, message, or a buffered line that has no newline termination.

The C<peek_line> option, when true, will cause this to return C<'peek'> and a
buffered line not terminated by a newline, if such a line has been read and is
pending in the buffer. Calling this multiple times will return the same peek
line (and anything added to the buffer since the last read) until the buffer
reads a newline or hits EOF.

When C<compression> and C<keep_compressed> are both enabled, the C<burst> and
C<message> return paths additionally yield a C<< compressed => $raw_bytes >>
pair:

    (burst   => $decompressed, compressed => $raw)
    (message => $decompressed, compressed => $raw)

Under L</compress_large_only> bursts and plain messages never include a
C<compressed> key; only messages that were sent compressed do.

The C<line> and C<peek> paths never include a C<compressed> key. The 2-tuple
idiom

    my ($type, $data) = $p->get_line_burst_or_data;

remains valid; the extra elements are simply discarded.

=back

=head3 COMPRESSION METHODS

=over 4

=item $algo_or_undef = $p->compression

=item $level_or_undef = $p->compression_level

=item $bytes_or_undef = $p->compression_dictionary

=item $path_or_undef = $p->compression_dictionary_file

=item $bool = $p->keep_compressed

=item $bool = $p->compress_large_only

=item $bytes_or_undef = $p->compression_threshold

Read-only accessors for the corresponding compression settings. See
L</COMPRESSION>. C<compression_threshold> returns the threshold in use while
C<compress_large_only> is on, including the default (4080 bytes on Linux,
4077 in mixed-data mode), and undef when it is off.

=item $p->set_compression('zstd', $level)

=item $p->set_compression(undef)

Enable, change, or disable compression on an existing pipe. C<$level> is
optional; calling C<< $p->set_compression('zstd') >> with no level preserves
whatever level was previously set. To reset the level to its default, call
C<< $p->set_compression(undef) >> first (which clears compression, level,
and any cached compressors), then re-enable.

C<set_compression(undef)> does B<not> clear C<compression_dictionary> or
C<compression_dictionary_file>; the dictionary is preserved across
disable/re-enable. Use the dictionary setters to clear those slots.

=item $p->set_compression_dictionary($bytes)

=item $p->set_compression_dictionary(undef)

Set, replace, or clear the raw-bytes dictionary. Setting clears any
file-path dictionary (mutually exclusive). Cached preprocessed dictionaries
are rebuilt on next compress/decompress.

=item $p->set_compression_dictionary_file($path)

=item $p->set_compression_dictionary_file(undef)

Set, replace, or clear the file-path dictionary. Setting clears any
raw-bytes dictionary.

=item $p->set_keep_compressed($bool)

Toggle whether reads expose the raw compressed bytes alongside the
decompressed payload.

=item $p->set_compress_large_only($bool)

=item $p->set_compress_large_only(1, $threshold)

Turn L</"Compressing only large messages"> on or off. C<$threshold> is
optional; without it the default is used (one atomic part, 4080 bytes on
Linux). Turning it on enables C<zstd> compression if it is not already
enabled.

Turning it off undoes that: it clears the threshold, and if compression was
only on because of C<compress_large_only>, compression goes off too. If you
set C<compression> yourself, it stays on and the pipe goes back to
compressing every burst and message.

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
