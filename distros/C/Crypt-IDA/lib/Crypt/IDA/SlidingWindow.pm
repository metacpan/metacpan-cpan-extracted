package Crypt::IDA::SlidingWindow;

# Copyright (c) Declan Malone, 2019
#
# See LICENSE

# Sliding Window algorithm to support cleaner IDA split/combine code

use Class::Tiny qw(bundle yts splitting combining), {
    # our 5 pointers (not really meant to be passed to new)
    read_head => 0,		# first to be advanced
    read_tail => 0,		# } peri-
    processed => 0,		# } stal-
    write_head => 0,		# } sis 
    write_tail => 0,		# start of window; last to advance
    # substream pointers (could be on read end or write end)
    # bundle => set up in BUILD
    
    # required
    mode => undef,		# 'split' or 'combine'
    rows => undef,		# how many substreams in bundle?
    window => undef,

    # optional callbacks (might move to Algorithm?)
    cb_error => undef,
    cb_read_bundle => undef,
    cb_wrote_bundle => undef,
    cb_processed => undef,
};

sub BUILD {
    my ($self, $args) = @_;
    for my $req ( qw(mode rows window) ) {
	die "$req attribute required" unless defined $self->$req;
    }
    die "Bad mode!" unless
	$self->{mode} eq 'split' or $self->{mode} eq 'combine';
    for my $plus ( qw(rows window) ) {
	die "$plus attribute must be > 0" unless $self->$plus > 0;
    }
    for my $zero ( qw(read_head read_tail processed write_head
                      write_tail) ) {
	die "Setting $zero attribute not allowed" unless $self->$zero == 0;
    }

    # Need to set up yts
    $self->{yts} = $self->{rows};

    # Couldn't set up bundle in Class::Tiny call
    my @bundle;
    for (1 .. $self->{rows}) {
	push @bundle, { head => 0, tail => 0 }
    }
    $self->{bundle} = \@bundle;

    $self->splitting($self->{mode} eq 'split'   ? 1 : 0 );
    $self->combining($self->{mode} eq 'combine' ? 1 : 0 );

}

# 
sub _error {
    my ($self,@msg) = @_;
    my $cb = $self->{cb_error};
    return @msg unless defined $cb;
    $cb->(@msg);
    undef;
}

# For clarity, I won't combine advance_read and advance_write into a
# single sub. This makes it easier to understand what's happening in
# _advance_rw_substream.

sub advance_read {
    my ($self,$cols) = @_;

    die "Use advance_read_substream instead" if $self->{combining};
    my ($head,$tail) = ($self->{read_head}, $self->{read_tail});

    # Note that read_head can be up to two windows ahead of
    # write_tail, but never more than one window from read_tail.
    die "Would exceed read window" if $head + $cols - $tail > $self->{window};
    $self->{read_head} += $cols;
}

sub advance_write {
    my ($self,$cols) = @_;

    die "Use advance_write_substream instead" if $self->{splitting};
    my ($head,$tail) = ($self->{write_head}, $self->{write_tail});

    # Advance tail, but not past head.
    die "Write tail would overtake head" if $tail + $cols > $head;
    $self->{write_tail} += $cols;
}

# code for advancing read/write substreams is the same, apart from
# error messages, callbacks and overall pointer to possibly update
sub _advance_rw_substream;
sub advance_read_substream  { shift->_advance_rw_substream("read", @_) }
sub advance_write_substream { shift->_advance_rw_substream("write", @_)}


# Returns:
# * undef on error
# * 0 if OK and bundle pointer didn't advance
# * 1 if OK and bundle pointer did advance
sub _advance_rw_substream {
    my ($self,$which,$row,$cols) = @_;
    my ($ptr, $parent, $cb);
    if ($which eq "read") {
	die "No read substreams!" if $self->{splitting};
	($ptr, $parent, $cb) = ("head", "read_head", "cb_read_bundle")
    } elsif ($which eq "write") {
	die "No write substreams!" if $self->{combining};
	($ptr, $parent, $cb) = ("tail", "write_tail", "cb_wrote_bundle");
    } else {
	die "_advance_some_substream: $which?";
    }
    die "Row out of range" if $row >= $self->{rows};

    my $hash    = $self->{bundle}->[$row];
    my $old_val = $hash->{$ptr};
    if ($which eq "read") {
	die "Read would overflow input buffer"
	    if $old_val + $cols - $hash->{tail} > $self->{window};
    } else {
	die "Write tail would overtake head"
	    if $old_val + $cols > $hash->{head};
    }
    my $new_val = $hash->{$ptr} += $cols;

    # possibly advance parent pointer to new minimum
    return 0 unless $old_val == $self->{$parent};
    return 0 if --$self->{yts};

    my $new_yts = 1;
    for my $r (0 .. $self->{rows} - 1) {
	next if $r == $row;
	my $this_val = $self->{bundle}->[$r]->{$ptr};
	next if $this_val > $new_val;
	if ($this_val < $new_val) {
	    ($new_val, $new_yts) = ($this_val, 1);
	} else {
	    ++$new_yts;
	}
    }
    ($self->{$parent}, $self->{yts}) = ($new_val, $new_yts);
    $self->{$cb}->() if defined $self->{$cb};
    return 1;
}

# The names here reflect the names of the related I/O commands as used
# by the caller:
#
# * read_ok: how much should we read to fill input buffer?
# * process_ok: how much input can we process to produce output?
# * write_ok: how much should we write to empty output buffer?
# * bundle_ok: associated with read/write, depending on mode
#
# For multiple substreams, the parent read_ok/write_ok is the maximum
# of all the substream read_ok/write_ok values, so caller should use
# the substream read_ok/write_ok values to decide how much to
# read/write. The parent read_ok/write_ok values track when the bundle
# advances as a whole.
sub can_advance {
    my $self = shift;
    my ($read_ok, $process_ok, $write_ok, @bundle_ok);

    # reads fill and writes empty the buffers
    $read_ok  = $self->{window} - ($self->{read_head} - $self->{read_tail});
    $write_ok = ($self->{write_head} - $self->{write_tail});

    # processing limited by available input/free output space
    my $read_ready = $self->{read_head} - $self->{read_tail};
    my $write_free = $self->{window} - $write_ok;
    $process_ok = $read_ready < $write_free ? $read_ready : $write_free;

    # bundled substreams (could be read or write)
    if ($self->{combining}) {
	for my $row (0 .. $self->{rows} - 1) {
	    my $rowptr = $self->{bundle}->[$row];
	    push @bundle_ok, $self->{window} - ($rowptr->{head} - $rowptr->{tail});
	}
    } else {
	for my $row (0 .. $self->{rows} - 1) {
	    my $rowptr = $self->{bundle}->[$row];
	    push @bundle_ok, $rowptr->{head} - $rowptr->{tail};
	}
    }
    ($read_ok,$process_ok,$write_ok,\@bundle_ok);
}

sub can_fill {
    my $self = shift;
    die "use can_fill_substream instead" if $self->{combining};
    $self->{window} - ($self->{read_head} - $self->{read_tail});
}

sub can_empty {
    my $self = shift;
    die "use can_empty_substream instead" if $self->{splitting};
    $self->{write_head} - $self->{write_tail};
}

sub can_fill_substream {
    my ($self,$row) = @_;
    die "must specify a row" unless defined $row;
    die "use can_fill instead" if $self->{splitting};
    my $rowptr = $self->{bundle}->[$row];
    $self->{window} - ($rowptr->{head} - $rowptr->{tail})
}

sub can_empty_substream {
    my ($self,$row) = @_;
    die "must specify a row" unless defined $row;
    die "use can_empty instead" if $self->{combining};
    my $rowptr = $self->{bundle}->[$row];
    $rowptr->{head} - $rowptr->{tail};
}    
    

# advance_process advances all the "middle" pointers (ie, everything
# except read_head and write_tail) in a single operation
sub advance_process {
    my ($self,$cols) = @_;

    die "Not enough data in input buffer"
	if $self->{read_tail} + $cols > $self->{read_head};

    my $written    = ($self->{write_head} - $self->write_tail);
    my $write_free = $self->{window} - $written;
    die "Not enough space in output buffer" if $cols > $write_free;

    $self->{read_tail}  += $cols; # actually, all three can be
    $self->{processed}  += $cols; # handled with a single
    $self->{write_head} += $cols; # 'processed' pointer

    # Substreams could be on left/right, so different pointers get
    # advanced within them. Also implications for new "yet to start"?
    my ($new_yts,$new_val) = (0);
    if ($self->{combining}) {
	$new_val = $self->{read_tail}; 
	for my $r (0 .. $self->{rows} -1) {
	    my $new_subtail = $self->{bundle}->[$r]->{tail} += $cols;
	    die "Internal error" unless $new_subtail == $new_val;
	    #$new_yts++ if $self->{bundle}->[$r]->{tail} == $new_val;
	}
    } else {
	$new_val = $self->{write_head};
	for my $r (0 .. $self->{rows} -1) {
	    my $new_subhead = $self->{bundle}->[$r]->{head} += $cols;
	    die "Internal error" unless $new_subhead == $new_val;
	    #$new_yts++ if $self->{bundle}->[$r]->{tail} == $new_val;
	}
    }
    #warn "yts changed from $self->{yts} to $new_yts\n" 
    #	if $self->{yts} != $new_yts;
    #$self->yts($new_yts);
    return 0;
}

# Utility method to split some read/write into two contiguous
# reads/writes if it straddles the end of a buffer
sub destraddle {
    my ($self, $pointer, $cols) = @_;
    my $window    = $self->{window};
    my $rel_start = $pointer % $window;
    my $rel_end   = $rel_start + $cols;

    die "columns > window" if $cols > $window;

    # use <= because the point of this routine is to break r/w into
    # contiguous r/w's rather than informing about wrap-around
    return ($cols) if ($rel_end <= $window);

    my $second = $rel_end - $window;
    my $first  = $cols - $second;
    return ($first, $second);
}

1;

__END__
=pod

=head1 NAME

Crypt::IDA::SlidingWindow - Abstract Sliding Window class


=head1 SYNOPSIS

  use Crypt::IDA::SlidingWindow

  my $sw = Crypt::IDA::SlidingWindow->new(
    mode => 'split', rows => 4, window => 16384 );

  # accessors (can also use $sw->{variable} form)
  my $read_head = $sw->read_head;
  my $window    = $sw->window;   #...

  # Testing what can advance
  my ($read_ok, $process_ok, $write_ok, @bundle_ok)
    = $sw->can_advance;
  my $read_ok = $sw->can_fill;
  my $read_ok = $sw->can_fill_substream($row);
  my $process_ok = $sw->process_ok;
  my $write_ok = $sw->can_empty;
  my $write_ok = $sw->can_empty_substream($row);

  # advance pointers after ...
  $sw->advance_read($cols);                # filling input stream
  $sw->advance_read_substream($row,$cols); # filling input substream
  $sw->advance_process($cols);             # processing
  $sw->advance_write($cols);               # emptying output stream
  $sw->advance_write_substream($row,$cols);# emptying output substream

=head1 WARNING

This class is not meant to be called directly. Its functionality can
be accessed via method calls in C<Crypt::IDA::Algorithm>. It's also
possible that it may change in future:

=over

=item * the underlying object may change from {} to [] for more
        efficiency

=item * likewise, I might replace it with an XS library

=item * the callback feature might change or disappear (moved to
        C<Crypt::IDA::Algorithm>)

=back


=head1 DESCRIPTION

This class implements a I<Sliding Window> algorithm to support
cleaner IDA split/combine code. It manages access to the input and
output matrix buffers to prevent them from overflowing.

The abstraction assumes that:

=over

=item * all pointers refer to matrix I<columns> rather than bytes

=item * input and output matrices have the same number of columns

=item * pointers are linear (always increasing), rather than circular

=item * we're doing IDA-like split/combine operations with one matrix handling a "bundle" of substreams:

=over

=item * When splitting, single stream on input, bundle of substreams on output

=item * When combining, bundle of substreams on input, single stream on output

=back

=back

The class manages three types of pointer:

=over

=item * a 'read' ('fill') pointer tracking input into the input matrix

=item * a 'processed' pointer tracking transformation of input into output

=item * a 'write' ('empty') pointer tracking data being removed from the output matrix

=back

These should be self-explanatory.

=head2 Converting from Linear to Circular Reads/Writes

Internally, all the pointers are linear, but it's possible to convert
them to circular pointers within the input or output matrices. Simply:

=over

=item * calculate C<pointer % window_size>

=item * multiply that value by the size in bytes of a matrix column

=back

This class also provides a convenience method C<destraddle> that takes
a pointer and a number of columns to increase it by and checks whether
that range would cross the end of the matrix boundary. It returns:

=over

=item * the same I<columns> parameter, if the range is contiguous
within the matrix

=item * two I<columns> values representing contiguous ranges at the end and start of the matrix, respectively, otherwise

=back

For example:

 # Read a row of bytes from a matrix, handling wrap-around
 my ($first,$second) = $sw->destraddle($tail,$cols);
 my $rel_col = $tail % $sw->{window};
 $str = $mat->getvals($row,$rel_col,$first ,$order);
 $str.= $mat->getvals($row,0,       $second,$order) if defined($second);


=head2 Substream Bundles

This class maintains an extra set of head and tail pointers for each
substream, in addition to the main head/tail pointer. It's assumed
that substreams can advance at different rates from each other.

The code for C<advance_read_substream> and C<advance_write_substream>
checks whether advancing that substream can advance the parent
read/writer, and does so automatically. Callers can check the return
value of the method calls, with 1 indicating that the parent pointer
advanced.

When the parent pointer advances, it indicates either:

=over

=item * when combining, all input substreams got some input, so more
        processing can be done (providing there is output space)

=item * when splitting, all output substreams flushed some share data,
        so more processing can be done (providing there's more input
        data).

=back

In the current version of the code, it's also possible to pass a
callback to receive notification whenever a bundle of substreams makes
progress in this way:

 # when splitting, get callback when all output substreams advance
 $sw->cb_write_bundle(sub {...});
 
 # when splitting, get callback when all input substreams advance
 $sw->cb_read_bundle(sub {...}

This might change in future.

=head1 AUTHOR

Declan Malone, E<lt>idablack@sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to the file "GNU_GPL.txt" in this distribution for
details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
