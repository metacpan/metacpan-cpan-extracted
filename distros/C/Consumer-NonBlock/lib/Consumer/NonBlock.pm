package Consumer::NonBlock;
use strict;
use warnings;

our $VERSION = '0.002';

use IO::Handle;
use File::Spec;

use File::Path qw/remove_tree/;
use File::Temp qw/tempdir/;
use Fcntl qw/:flock/;
use Carp qw/croak confess/;
use Time::HiRes qw/sleep/;

use Object::HashBase qw{
    <dir
    <batch_size
    <use_shm

    <is_reader
    <is_writer

    <is_weak

    +fh
    +batch
    +batch_item
    +buffer
};

sub weaken { $_[0]->{+IS_WEAK} = 1 };

sub init {
    my $self = shift;

    croak "Must be either a reader or a writer" unless $self->{+IS_READER} || $self->{+IS_WRITER};
    croak "Must only be a reader or a writer, not both" if $self->{+IS_READER} && $self->{+IS_WRITER};

    my $dir = $self->{+DIR} or croak "'dir' is a required attribute";
    croak "Invalid directory '$dir'" unless -d $dir;

    if ($self->{+IS_WRITER}) {
        my $data = $self->_update(mode => '+>', open => 1, batch_size => $self->{+BATCH_SIZE} // 100);
        $self->{+BATCH_SIZE} //= $data->{batch_size};
    }
    else {
        my $data = $self->_update();
        $self->{+BATCH_SIZE} //= $data->{batch_size};
        croak "Could not find batch size" unless defined $self->{+BATCH_SIZE};
    }

    delete $self->{+FH};

    $self->{+BATCH}      = 0;
    $self->{+BATCH_ITEM} = 0;
}

sub pair {
    my $class = shift;
    my (%params) = @_;

    my $dir;
    my $base = $params{base_dir} // ($params{shm} ? '/dev/shm' : ());
    if ($base) {
        croak "base dir '$base' is not valid" unless -d $base;
        $dir = tempdir("ConsumerNonBlock-$$-XXXXXX", CLEANUP => 0, DIR => $base);
    }
    else {
        $dir = tempdir("ConsumerNonBlock-$$-XXXXXX", CLEANUP => 0, TMPDIR => 1);
    }

    my $batch_size = $params{+BATCH_SIZE} // 100;

    $params{+BATCH_SIZE} = $batch_size;
    $params{+DIR} = $dir;

    my $writer = $class->new(%params, is_writer => 1);
    my $reader = $class->new(%params, is_reader => 1);

    return ($reader, $writer);
}

sub reader {
    my $class = shift;
    my ($dir, %params) = @_;
    return $class->new(%params, DIR() => $dir, is_reader => 1);
}

sub reader_from_env {
    my $class = shift;
    my $dir = $ENV{CONSUMER_NONBLOCK_DIR} or croak 'The $CONSUMER_NONBLOCK_DIR env var is not set';
    $class->reader($dir, @_);
}

sub writer {
    my $class = shift;
    my ($dir, %params) = @_;
    return $class->new(batch_size => 100, %params, DIR() => $dir, is_writer => 1);
}

sub _data_file {
    my $self_or_class = shift;
    my ($dir) = @_;

    unless ($dir) {
        croak "Cannot call data_file() on a class, must use an instance or pass in a directory"
            unless ref $self_or_class;

        $dir = $self_or_class->dir;
    }

    return File::Spec->catfile($dir, 'data');
}

sub _update {
    my $self = shift;
    my %data = @_;
    my $write = @_;

    my $df = $self->_data_file;

    my $mode = delete($data{mode}) || '+<';

    open(my $fh, $mode, $df) or confess "Could not open file '$df': $!";
    flock($fh, $write ? LOCK_EX : LOCK_SH) or confess "Could not lock file '$df': $!";

    while (my $line = <$fh>) {
        my ($key, $val) = ($line =~ m/^([^:]+):(.+)$/);
        next unless $key;
        $data{$key} //= $val;
    }

    if ($write) {
        seek($fh, 0, 0);
        print $fh "$_\:$data{$_}\n" for keys %data;
    }

    $fh->flush();

    flock($fh, LOCK_UN) or confess "Could not unlock file '$df': $!";
    close($fh);

    return \%data;
}

sub set_env_var {
    my $self = shift;
    $ENV{CONSUMER_NONBLOCK_DIR} = $self->{+DIR};
}

sub write {
    my $self = shift;
    my $count = 0;

    for my $item (@_) {
        next unless defined $item;

        for my $line (split /\n/, $item) {
            $count++;
            $self->write_line($line);
        }
    }

    return $count;
}

sub _check_batch_boundary {
    my $self = shift;
    my (%params) = @_;

    return if $self->{+BATCH_ITEM} < $self->{+BATCH_SIZE};

    delete $self->{+FH};
    $self->{+BATCH_ITEM} = 0;

    unlink(File::Spec->catfile($self->{+DIR}, $self->{+BATCH}))
        if $params{delete};

    $self->{+BATCH} += 1;

    return;
}

sub _batch_fh {
    my $self = shift;
    my ($mode) = @_;

    return $self->{+FH} if $self->{+FH};

    my $file = File::Spec->catfile($self->{+DIR}, $self->{+BATCH});
    my $fh;

    # Only open it if it exists, or we are creating it.
    return unless -e $file || $mode eq '>';

    open($fh, $mode, $file);
    return $self->{+FH} = $fh;
}

sub write_raw {
    my $self = shift;
    my ($raw) = @_;

    croak "No data to write" unless defined $raw;

    $self->_check_batch_boundary();
    my $fh = $self->_batch_fh('>');

    print $fh $raw;
    $fh->flush();
    $self->{+BATCH_ITEM}++;

    return;
}

sub write_line {
    my $self = shift;
    my ($line) = @_;

    croak "No line to write" unless defined $line;

    chomp($line);

    $self->_check_batch_boundary();
    my $fh = $self->_batch_fh('>');

    print $fh $line, "\n";
    $self->{+BATCH_ITEM}++;

    return;
}

sub read_line {
    my $self = shift;

    my $buffer = \$self->{+BUFFER};

    my $loop = 0;
    while (1) {
        # There must be a better way, maybe INotify?
        sleep(0.02) if $loop;
        $loop ||= 1;

        $self->_check_batch_boundary(delete => 1);

        my ($fh, $line);

        if ($fh = $self->_batch_fh('<')) {
            seek($fh, 0, 1) if $fh->eof;
            $line = <$fh>;
            if (defined $line) {
                unless (chomp($line)) {
                    $$buffer = defined($$buffer) ? $$buffer . $line : $line;
                    next;
                }
            }
        }

        if ($fh && defined $line) {
            $self->{+BATCH_ITEM}++;
            if ($$buffer) {
                delete $self->{+BUFFER};
                return $$buffer . $line if $$buffer;
            }

            return $line;
        }
        else {
            my $data = $self->_update();
            next if $data->{open};

            unlink(File::Spec->catfile($self->{+DIR}, $self->{+BATCH}));

            return undef;
        }
    }
}

sub read_lines {
    my $self = shift;
    my @out;

    while (my $line = $self->read_line) {
        push @out => $line;
    }

    return @out;
}

sub DESTROY {
    my $self = shift;

    return if $self->is_weak;

    if ($self->{+IS_WRITER}) {
        $self->_update(open => 0);
        return;
    }

    if ($self->{+IS_READER}) {
        remove_tree($self->{+DIR}, {safe => 1, keep_root => 0});
        return;
    }
}

sub close { $_[0] = undef }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Consumer::NonBlock - Send data between processes without blocking.

=head1 DESCRIPTION

It is very easy to end up in a situation where a producer process produces data
faster than a consumer process can read/process it resulting in the producer
blocking on a full pipe buffer. This module allows 2 processes to share data
similar to a pipe, but without the producer blocking due to full pipe buffers.

A pipe is better in most situations, this is only useful if the producer needs
to do many things and you cannot afford to block on a consumer. This is used by
L<App::Yath> to send data to a comparatively slow database upload process
without blocking.

=head1 SYNOPSIS

    use Consumer::NonBlock;

    my ($reader, $writer) = Consumer::NonBlock->pair(batch_size => 100);

    $writer->write_line("A line!");
    $writer->write("several\nlines\n", "in\nseveral\nstrings\n");

    my $line1 = $reader->read_line();
    # "A line!"

    my @lines = $reader->read_lines();
    # "several"
    # "lines"
    # "in"
    # "several"
    # "strings"

    $writer = undef; # Close the output
    $reader = undef; # Close the input, and delete the temp dir

=head1 SYNOPSYS WITH FORK

Normally when the reader is closed it will delete the data. Normally when the
writer is closed it will mark the data stream as complete. If you fork then
either of these actions can happen in either process.

The weaken() method can be used to prevent a reader or writer from taking these
actions. So in the producer process you want to weaken the reader object, and
in the consumer process you want to weaken the writer object.

    use Consumer::NonBlock;

    my ($reader, $writer) = Consumer::NonBlock->pair(batch_size => 100);

    my $pid = fork // die "Could not fork: $!";

    if ($pid) { # Parent
        # Make sure this process does not delete the temp data
        $reader->weaken;
        $reader->close;

        $writer->write_line("Line from the parent");
    }
    else { # Child
        # Make sure this process does not mark the IO as complete
        $writer->weaken;
        $writer->close;

        my $line = $reader->read_line;
        print "Got line: $line\n";
    }

=head1 IMPLEMENTATION DETAILS

This module works by having the producer write to temporary files. It will
rotate files after a specified batch limit. The consumer will delete the files
as it finishes with them to prevent having data we already processed sitting on
disk. For best performance /var/shm should be used.

=over 4

=back

=head1 METHODS

=over 4

=item ($reader, $writer) = Consumer::NonBlock->pair()

=item ($reader, $writer) = Consumer::NonBlock->pair(batch_size => 100, use_shm => $BOOL)

Create a reader and writer pair.

Optionally specify a batch size, default is 100.

Optionally request that data be stored in /var/shm.

=item $writer = Consumer::NonBlock->writer($DIR)

=item $writer = Consumer::NonBlock->writer($DIR, batch_size => 100)

Create a writer in the specified directory.

=item $reader = Consumer::NonBlock->reader($DIR)

Create a reader on a specified directory.

=item $reader = Consumer::NonBlock->reader_from_env()

Create a reader using the C<$ENV{CONSUMER_NONBLOCK_DIR}> env var.

=item $handle = Consumer::NonBlock->new(dir => $DIR, is_reader => $BOOL, is_writer => $BOOL, batch_size => $INT)

Not recommended, use C<pair()>, C<reader()>, or C<writer()>.

=item $dir = $handle->dir()

Get the temporary data directory.

=item $batch_size = $handle->batch_size()

Get the batch size.

=item $bool = $handle->use_shm()

Check if /var/shm is being used.

=item $bool = $handle->is_reader()

Check if handle is a reader.

=item $bool = $handle->is_writer()

Check if handle is a writer.

=item $bool = $handle->is_weak()

Check if the handle has been weakened.

=item $handle->weaken()

Weaken the handle so it will not delete the data dir or close the IO.

=item $handle->set_env_var()

Sets the C<$ENV{CONSUMER_NONBLOCK_DIR}> env var to the temporary data dir. This
can then be used in a child process with
C<< Consumer::NonBlock->reader_from_env() >> to create a reader instance in
another process.

=item $line_count = $handle->write($text1, $text2, ...)

Write arbitrary text data with arbitrary line breaks. Line breaks B<WILL> be
added between arguments.

Returns number of lines written.

=item $handle->write_line($line)

Write a single line of data. No validation is done to verify the input line.
Having line-breaks inside the input line B<WILL>corrupt data.

=item $line = $handle->read_line()

Retrieve a single line from the handle. Will block until data is available or
until the writer is closed.

=item @lines = $handle->read_lines()

Retrieve all lines, will block until writer is closed.

=item $handle->close

Will close the handle. If this is a writer it will close the stream. If this is
a reader it will delete the data dir. $handle will be set to undef.

=back

=head1 SOURCE

The source code repository for Consumer-NonBlock can be found at
L<http://github.com/exodist/Consumer-NonBlock/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

