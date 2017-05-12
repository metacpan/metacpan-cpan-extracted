package Acme::InputRecordSeparatorIsRegexp;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Symbol;

BEGIN {
    no strict 'refs';
    *{ 'Acme::IRSRegexp' . "::" } = \*{ __PACKAGE__ . "::" };
}

our $VERSION = '0.03';

sub TIEHANDLE {
    my ($pkg, @opts) = @_;
    my $handle;
    if (@opts % 2) {
	$handle = Symbol::gensym;
    } else {
	my $fh = *{shift @opts};
	open $handle, '<&+', $fh;
    }
    my $rs = shift @opts;
    my %opts = @opts;
    $opts{maxrecsize} ||= ($opts{bufsize} || 16384) / 4;
    $opts{bufsize} ||= $opts{maxrecsize} * 4;
    my $self = bless {
	%opts,
	handle => $handle,
	rs => $rs,
	records => [],
	buffer => ''
    }, $pkg;
    $self->_compile_rs;
    return $self;
}

sub _compile_rs {
    my $self = shift;
    my $rs = $self->{rs};

    my $q = eval { my @q = split /(?<=${rs})/,""; 1 };
    if ($q) {
	$self->{rsc} = qr/(?<=${rs})/;
	$self->{can_use_lookbehind} = 1;
    } else {
	$self->{rsc} = qr/(.*?(?:${rs}))/;
	$self->{can_use_lookbehind} = 0;
    }
    return;
}

sub READLINE {
    my $self = shift;
    if (wantarray) {
	local $/ = undef;
	$self->{buffer} .= readline($self->{handle});
	push @{$self->{records}}, $self->_split;
	$self->{buffer} = "";
	my @rec = splice @{$self->{records}};
	if (@rec && $self->{autochomp}) {
	    $self->chomp( @rec );
	}
	return @rec;
    }
    # want scalar
    if (!@{$self->{records}}) {
	$self->_populate_buffer;
    }
    my $rec = shift @{$self->{records}};
    if (defined($rec) && $self->{autochomp}) {
	$self->chomp( $rec );
    }
    return $rec;
}

sub _populate_buffer {
    my $self = shift;
    my $handle = $self->{handle};
    return if !$handle || eof($handle);
    
#    my $rs = $self->{rsc} || $self->{rs};
    my @rec;
    {
	my $buffer = '';
	my $n = read $handle, $buffer, $self->{bufsize};
	$self->{buffer} .= $buffer;
	@rec = $self->_split;
	redo if !eof($handle) && @rec == 1;
    }
    push @{$self->{records}}, @rec;
    $self->{buffer} = '';
    if (eof($handle)) {
	return;
    }

    if (@{$self->{records}} > 1) {
	$self->{buffer} = pop @{$self->{records}};
    }
    return;
}

sub EOF {
    my $self = shift;
    foreach my $rec (@{$self->{records}}, $self->{buffer}) {
	return if length($rec) > 0;
    }
    return eof($self->{handle});
}

sub _split {
    my $self = shift;
    if (!defined $self->{can_use_lookbehind}) {
	$self->_compile_rs;
    }
    my $rs = $self->{rsc};
    my @rec = split $rs, $self->{buffer};
    if ($self->{can_use_lookbehind}) {
	return @rec;
    } else {
	return grep length, @rec;
    }
}

sub CLOSE {
    my $self = shift;
    $self->_clear_buffer;
    my $z = close $self->{handle};
    # delete $self->{handle};
    return $z;
}

sub _clear_buffer {
    my $self = shift;
    $self->{buffer} = '';
    $self->{records} = [];
}

sub OPEN {
    my ($self, $mode, @args) = @_;
    if ($self->{handle}) {
	# close $self->{handle};
    }
    my $z = CORE::open $self->{handle}, $mode, @args;
    if ($z) {
	$self->_clear_buffer;
    }
    return $z;
}

sub input_record_separator {
    my $self = shift;
    if (@_) {
	$self->{rs} = shift;
	delete $self->{can_use_lookbehind};
    }
    $self->_compile_rs;
    return $self->{rs};
}

sub FILENO {
    my $self = shift;
    return fileno($self->{handle});
}

sub WRITE {
    my ($self, $buf, $len, $offset) = @_;
    $offset ||= 0;
    if (!defined $len) {
	$len = length($buf)-$offset;
    }
    $self->PRINT( substr($buf,$offset,$len) );
}

sub PRINT {
    my ($self, @msg) = @_;
    if ($self->TELL() != tell($self->{handle})) {
	$self->SEEK(0,1);
    } else {
	$self->_clear_buffer;
    }
    print {$self->{handle}} @msg;
}

sub PRINTF {
    my ($self, $template, @args) = @_;
    $self->PRINT(sprintf($template,@args));
}

sub READ {
    my $self = shift;
    my $bufref = \$_[0];
    my (undef, $len, $offset) = @_;
    my $nread = 0;

    while ($len > 0 && @{$self->{records}}) {
	if (length($self->{records}[0])>=$len) {
	    my $rec = shift @{$self->{records}};
	    my $reclen = length($rec);
	    substr( $$bufref, $offset, $reclen, $rec);
	    $len -= $reclen;
	    $offset += $reclen;
	    $nread += $reclen;
	} else {
	    my $rec = substr($self->{records}[0], 0, $len, "");
	    substr( $$bufref, $offset, $len, $rec);
	    $offset += $len;
	    $nread += $len;
	    $len = 0;
	}
    }
    if ($len > 0 && length($self->{buffer}) > 0) {
	my $reclen = length($self->{buffer});
	if ($reclen >= $len) {
	    my $rec = substr( $self->{buffer}, 0, $len, "" );
	    substr( $$bufref, $offset, $len, $rec );
	    $offset += $len;
	    $nread += $len;
	    $len = 0;
	} else {
	    substr( $$bufref, $offset, $reclen, $self->{buffer} );
	    $self->{buffer} = "";
	    $offset += $reclen;
	    $nread += $reclen;
	    $len -= $reclen;
	}
    }
    if ($len > 0) {
	return $nread + read $self->{handle}, $$bufref, $len, $offset;
    } else {
	return $nread;
    }
}

sub GETC {
    my $self = shift;
    if (@{$self->{records}}==0 && 0 == length($self->{buffer})) {
	$self->_populate_buffer;
    }

    if (@{$self->{records}}) {
	my $c = substr( $self->{records}[0], 0, 1, "" );
	if (0 == length($self->{records}[0])) {
	    shift @{$self->{records}};
	}
	return $c;
    } elsif (0 != length($self->{buffer})) {
	my $c = substr( $self->{buffer}, 0, 1, "" );
	return $c;
    } else {
	# eof?
	return undef;
    }
}

sub BINMODE {
    my $self = shift;
    my $handle = $self->{handle};
    if (@_) {
	binmode $handle, @_;
    } else {
	binmode $handle;
    }    
}

sub SEEK {
    my ($self, $pos, $whence) = @_;

    if ($whence == 1) {
	$whence = 0;
	$pos += $self->TELL;
    }

    # easy implementation:
    #     on any seek, clear records, buffer

    $self->_clear_buffer;
    seek $self->{handle}, $pos, $whence;

    # more sophisticated implementation
    #     on a seek forward, remove bytes from the front
    #     of buffered data
}

sub TELL {
    my $self = shift;
    # virtual cursor position is actual position on the filehandle
    # minus the length of any buffered data
    my $tell = tell $self->{handle};
    $tell -= length($self->{buffer});
    $tell -= length($_) for @{$self->{records}};
    return $tell;
}

sub open {
    shift if $_[0] eq __PACKAGE__;
    my ($regex, $mode, @args) = @_;
    my %opts;
    if (@args && ref $args[-1] eq 'HASH') {
	%opts = %{pop @args};
    }
    my $fh = Symbol::gensym;
    my $hh;
    my $z = CORE::open $hh, $mode, @args;
    return if !$z;
    tie *$fh, __PACKAGE__, $hh, $regex, %opts;
    return $fh;
}

sub chomp {
    my $self = shift;
    my $removed = 0;
    my $rs = $self->{rs};
    foreach my $line (@_) {
	$line =~ s/($rs)$//;
	if (defined($1)) {
	    $removed += length($1);
	}
    }
    return $removed;
}

1; # 

__END__

=head1 NAME

Acme::InputRecordSeparatorIsRegexp - awk doesn't have to be better at something.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Acme::InputRecordSeparatorIsRegexp;

    # open-then-tie
    open my $fh, '<', 'file-with-Win-Mac-and-Unix-line-endings';
    tie *$fh, 'Acme::IRSRegexp', $fh, '\r\n|\n|\r';
    while (<$fh>) {
        # $_ could have "\r\n", "\n", or "\r" line ending now
    }

    # tie-then-open
    tie *{$fh=Symbol::gensym}, 'Acme::IRSRegExp', qr/\r\n|[\r\n]/;
    open $fh, '<', 'file-with-ambiguous-line-endings';
    $line = <$fh>;

=head1 DESCRIPTION

In the section about the L<"input record separator"|perlvar/"$/">,
C<perlvar> famously notes

=over 4

Remember: the value of $/ is a string, not a regex. B<awk>
has to be better for something. :-)

=back

This module provides a mechanism to read records from a file
using a regular expression as a record separator.

A common use case for this module is to read a text file 
that you don't know whether it uses Unix (C<\n>), 
Windows/DOS (C<\r\n>), or Mac (C<\r>) style line-endings, 
or even if it might contain all three. To properly parse
this file, you could tie its filehandle to this package with
the appropriate regular expression:

    my $fh = Symbol::gensym;
    tie *$fh, 'Acme::InputRecordSeparatorIsRegexp', '\r\n|\r|\n';
    open $fh, '<', 'file-with-ambiguous-line-endings';

    @lines = <$fh>;
    # or
    while (my $line = <$fh>) { ... }

The lines produced by the C<< <$fh> >> expression, like the
builtin C<readline> function and operator, include the record
separator at the end of the line, so the lines returned may end
in C<\r\n>, C<\r>, or C<\n>.

Other use cases are files that contain multiple types of records
where a different sequence of characters is used to denote the
end of different types of records.

=head1 tie STATEMENT

A typical use of this package might look like

    my $fh = Symbol::gensym;
    tie *$fh, 'Acme::InputRecordSeparatorIsRegexp', $record_sep_regex;
    open $fh, '<', $filename;

where C<$record_sep_regexp> is a string or a C<Regexp> object 
(specified with the 
L<< C<qr/.../>|"Quote and quote-like operators"/perlop >> notation)
containing the regular expression
you want to use for a file's line endings. Also see the convenience
method L<"open"> for an alternate way to obtain a filehandle with
the features of this package.

=head1 METHODS

=head2 open

   my $tied_handle = Acme::InputRecordSeparatorIsRegexp->open(
	$record_separator_regexp, $mode, @openargs);

Convenience method to open a file, returning a tied filehandle
that will read and return records separated according the given regular
expression. Returns C<undef> and sets C<$!> on error.
C<%tie_opts> if any, are included in the call to 
C<tie *HANDLE, 'Acme::InputRecordSeparatorIsRegexp'>.

=head2 input_record_separator

    my $rs = (tied *$fh)->input_record_separator();
    (tied *$fh)->input_record_separator($new_record_separator);

Get or set the input record separator used for this tied filehandle.
The argument, if provided, can be a string or a C<Regexp> object.

=head2 chomp

    my $chars_removed = (tied *$fh)->chomp($line_from_fh);
    my $chars_removed = (tied *$fh)->chomp(@lines_from_fh);

Like the builtin L<< C<chomp>|"chomp"/perlvar >> function,
but removes the trailing string from lines that correspond to
the file handle's custom input record separator regular
expression instead of C<$/>. Like the builtin C<chomp>,
returns the total number of characters removed from
all its arguments. See also L<"autochomp">.

=head2 autochomp

    my $ac = (tied *$fh)->autochomp;
    (tied *$fh)->autochomp($boolean);

Gets or sets the autochomp attribute of the filehandle.
If this attribute is set to a true value, readline 
operations on this filehandle will return records with
the record separators removed.

The default value of this attribute is false.

=head1 INTERNALS

In unusual circumstances, you may be interested in some of the
internals of the tied filehandle object. You can set the values
of these internals by passing additional arguments to the
C<tie> statement or passing a hash reference to this package's 
L<"open"> function, for example:

    my $th = Acme::InputRecordSeparatorIsRegexp->open( $regex, '<', $filename,
    			{ bufsize => 65336 } );

=head2 bufsize

The amount of data, in bytes, to read from the input stream at
a time. For performance reasons, this should be at least a few kilobytes.
For the module to work correctly, it should also be much larger
than the length of any sequence of characters that could be construed
as a line ending.

=head1 ALIAS

The package C<Acme::IRSRegexp> is an alias for
C<Acme::InputRecordSeparatorIsRegexp>, allowing you to write

    use Acme::InputRecordSeparatorIsRegexp;
    tie *$fh, 'Acme::IRSRegexp', 

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS, LIMITATIONS, AND OTHER NOTES

Because this package must often pre-fetch input to determine where
a line-ending is, it is generally not appropriate to apply this
package to C<STDIN> or other terminal-like input.

Changing C<$/> will have no affect on a filehandle that has
already been tied to this package.

Calling L<< C<chomp>|"chomp"/perlfunc >> on a return value from this
package will operate with C<$/>, B<not> with the regular expression
associated with the tied filehandle.

Please report any bugs or feature requests to C<bug-tie-handle-regexpirs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-InputRecordSeparatorIsRegexp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::InputRecordSeparatorIsRegexp

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-InputRecordSeparatorIsRegexp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-InputRecordSeparatorIsRegexp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-InputRecordSeparatorIsRegexp>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-InputRecordSeparatorIsRegexp/>

=back


=head1 ACKNOWLEDGEMENTS

L<perlvar>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

members

    handle           => *
    buffered_records => []
    buffer           => $
    rs               => $
    bufsize          => $
  X maxrecsize       => $

    autochomp        => bool

private methods

    _populate_buffer
    _split


test plan:

    read methods
    ------------
    READLINE
        scalar context
        list context
    READ
        with and without offset
        length < = > buffer allocated
        before and after populate buffer (i.e., after scalar READLINE)
    GETC
        with and without populated buffer (after SCALAR READLINE)
        at eof
    EOF
        with buffer populated

    SEEK & TELL
        move around, keep reading

    write methods
    -------------
    PRINT, PRINTF, WRITE (syswrite)

    misc methods
    ------------
    FILENO
    BINMODE
    OPEN

    data sources
    ------------
    regular file in < mode
    piped input? socket?
    regular file in <+ mode
    regular file in >>+ mode
    DATA filehandle
    in memory filehandle
    mock handle already tied to something else?

test data:
    data with random, different line endings (\n, \r, \r\n)

    random capital letters, split on ..., I dunno, [A-Z][XY]

    join a sequence of integers, split on 120|12|345|
    join a sequence of integers, split on 12|120|345|

TO DO:

_X_ let  rs  be a real regexp
    implement autochomp method
	implement chomp first
	call chomp on results as you return them
    implement chomp method
