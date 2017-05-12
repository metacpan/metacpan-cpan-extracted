package BoutrosLab::TSVStream::IO::Writer;

=head1 NAME

    BoutrosLab::TSVStream::IO::Writer

=cut

=head1 SYNOPSIS

This namespace hierarchy contains classes that can convert a series
of objects compatible with some type into an output stream (file
or handle).

=head1 DESCRIPTION

Usually, a writer object is created indirectly, using a
B<writer> method of the target class (which it acquires by
consuming the I<BoutrosLab::TSVStream::IO::Role::Fixed>, or
I<BoutrosLab::TSVStream::IO::Role::Dyn> role).

Since most of the attributes and methods of writers are the
same, this document describes them - there are differences
between Fixed and Dyn writers which are distinguished below.

It is recommended that when there are multiple formats possible for
a target class, they be implemented as a group of classes, where
each class in the group implements its attributes able to coerce
their value from any of the formats.  If that is done, then a file
in any of the formats (or even using a mixture of the formats)
can be used as the text stream and a reader will automatically
convert it to the format of the target class that the reader is
associated with.  Additionally, objects of any of the group of
classes can be provided to a writer from any of the group and it will
use the coercion to automatically convert to the desired format.
So, you choose a reader that matches the format you wish to use
for your programming code, and a writer for the format you wish for
the output.  The classes I<BoutrosLab::TSVStream::Format::AnnovarInput::Human>
and I<BoutrosLab::TSVStream::Format::AnnovarInput::NoChr> provide an example
of this.

=head1 Methods

=head2 new

	my $writer = Some::Class->writer(
		# class    => $class,        # (required) class
		handle     => $fd,           # (optional if file provided)
		file       => $file,         # (optional if handle provided)
		append     => 1,             # (optional) append to file
		header     => $str,          # (optional) write skip
		dyn_fields => $ref,          # (optional, Dyn only)
		extra_class_params => [...], # (optional) extra params for
		                             #     creating new class objects
	);

The B<new> method will usually be called indirectly from within
the B<writer> method of some other class.  Such a B<writer> method
will provide its own class as the B<class> argument to the B<new>
method, so the user calling the B<writer> method does not need to
provide it.  The B<writer> method will pass any arguments that the
caller provides to it on to the B<new> method.  This document will
refer to that other class as the related class.

At least one of the B<handle> and B<file> arguments must be provided.
If only the B<file> is provided, it will be opened for writing and
the B<handle> attribute will be initialized to that.  If B<handle> is
provided, it must be an open handle to a readable stream.  If errors
are encountered during processing, the B<file> (if provided) and line
number are used in the diagnostic - which means that even if you
are providing a B<handle>, it can be useful to provide the B<file>
argument as well to make the diagnostics clearer (unless your users
never make mistakes, of course).

If no B<handle> is provided, the B<file> is opened.  By default,
it is opened for normal write (overwriting any previous contents).
However, if the optional B<append> attribute is provided and has
a true value, the B<file> is instead opened for append.  If the
B<handle> attribute is provided, this B<append> attribute has
no effect.

If B<header> is provided, it can be C<'write'>, or C<'skip'>.
This controls what is done to the handle initially.

=over

If C<'write'> is specified, the field names are written as a header
to the stream before any data.  If C<'skip'> is specified, no header
is written before any data records.  The default is to C<'write'>
the headers.

If the optional B<pre_headers> attribute is provided, it must contain
an arrayref contining a list of comment lines that are to be written
before the header is written (if any).

=back

For Dyn writers, the B<dyn_fields> parameter can be passed to specify
the field names for the dynamic fields.  If not, and if headers are
being written.  then a default set of header names will be provided
(C<'extra1'>, C<'extra2'>, ...).

The B<extra_class_params> attribute accepts a ref to a list of
strings.  These will be passed to the I<new> method of the target
class when a set of values has been read.  This may be useful for
some target classes.  There is currently no generic use of this for
B<writer>.

=head2 write

The B<write> method takes arguments.  Usually, you will call it
with a single object of the target class, and its fields will be
written to the stream.

Alternatively, you can pass an object of a compatible class, an
array ref or a list of values.  These values will be validated
converted (if possible) into the target class and then written
(croaking if conversion fails).

=head2 write_comments

The B<write_comments> method takes an array ref containing lines
to be written verbatim to the output stream.  It is the caller's
respopnsibility to ensure that these lines are formatted properly
to match the commenting conventions for the targe TSVStream file
type.

=head2 _croak

    $writer->_croak("error message");

The C<_croak> method is needed internally, but may also be useful
in some cases by the code that uses the writer.  It croaks with
the supplied message, appending the filename and line number.

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO::Writer::Fixed

=item BoutrosLab::TSVStream::IO::Writer::Dyn

These are the two classes of writer - which read streams containing
either only the fields of the consumed class (Fixed), or the fields
of the consumed class followed by an additional dynamic set of fields
(Dyn).

=item BoutrosLab::TSVStream::Format

Describes the hierarchy of provided modules that define a
set of attributes that are useful to move to/from a text
stream.

=item BoutrosLab::TSVStream::Format::None::Dyn

A class that has no fixed fields, just dynamic fields.  It is useful
for processing one-off files where there is no value in going to the
work of creating an entire class for that file format.

=item BoutrosLab::TSVStream::IO

Describes the format of a text stream that a writer can read from.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

