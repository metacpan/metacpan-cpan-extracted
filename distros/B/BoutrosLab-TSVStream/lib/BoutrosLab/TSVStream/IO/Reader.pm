package BoutrosLab::TSVStream::IO::Reader;

=head1 NAME

    BoutrosLab::TSVStream::IO::Reader

=cut

=head1 SYNOPSIS

This namespace hierarchy contains classes that can convert an input
stream (file or handle) into a series of objects of some type.

=head1 DESCRIPTION

Usually, a reader object is created indirectly, using a
reader method of the target class (which it acquires by
consuming the BoutrosLab::TSVStream::IO::Role::Fixed, or
BoutrosLab::TSVStream::IO::Role::Dyn role).

Since most of the attributes and methods of readers are the
same, this document describes them - there are differences
between Fixed and Dyn readers which are distinguished below.

It is recommended that when there are multiple formats possible for
a target class, they be implemented as a group of classes, where
each class in the group implements its attributes able to coerce
their value from any of the formats.  If that is done, then a file
in any of the formats (or even using a mixture of the formats)
can be used as the text stream and a reader will automatically
convert it to the format of the target class that the reader is
associated with.  Additionally, objects of any of the group of
classes can be provided to a writer from any of the group and it
will use the coercion to automatically convert to the desired format.
So, you choose a reader that matches the format you wish to use for
your programming code, and a writer for the format you wish for the
output.  The classes BoutrosLab::TSVStream::Format::AnnovarInput::Human and
BoutrosLab::TSVStream::Format::AnnovarInput::NoChr provide an example of this.

=head1 Methods

=head2 new

	my $reader = Some::Class->reader(
		# class  => $class,          # (required) class
		handle => $fd,               # (optional if file provided)
		file   => $file,             # (optional if handle provided)
		header => $str,              # (optional) auto check none
		comment => 1,                # (optional) Bool: default 0
		dyn_fields => $ref,          # (optional, Dyn only)
		extra_class_params => [...], # (optional) extra params for
		                             #     creating new class objects
	);

The B<new> method will usually be called indirectly from within
the B<reader> method of some other class.  Such a B<reader> method
will provide its own class as the B<class> argument to the B<new>
method, so the user calling the B<reader> method does not need to
provide it.  The B<reader> method will pass any arguments that the
caller provides to it on to the B<new> method.  This document will
refer to that other class as the related class.

At least one of the B<handle> and B<file> arguments must be provided.
If only the B<file> is provided, it will be opened for reading and
the B<handle> attribute will be initialized to that.  If B<handle> is
provided, it must be an open handle to a readable stream.  If errors
are encountered during processing, the B<file> (if provided) and line
number are used in the diagnostic - which means that even if you
are providing a B<handle>, it can be useful to provide the B<file>
argument as well to make the diagnostics clearer (unless your users
never make mistakes, of course).

If B<header> is provided, it can be C<'check'>, C<'none'>,
or C<'auto'>.  This controls what is done to the handle initially.

=over

If C<'check'> is specified, the first line of the stream is read.
The fields in that line are checked to ensure that they match the
names of the fixed
fields of the related class, both in name and order.  However, it
is permitted for the field names to mismatch by having different
capitalization - the comparison is not case sensitive.  (Dyn only:
if the B<dyn_fields> attribute was provided, the dynamic fields
will also be validated (possibly
causing the stream to be rejected); otherwise, if B<dyn_fields>
was not provided, the attribute be set to contain the field names
that follow the validated fixed field names.)

If C<'none'> is specified, the stream is not checked for a header
line, the first line is treated as a data line.  You would use this
option either if the file does not have a header line, or if you are
scanning from the middle of a file handle that is no longer at the
start of the file.  In this case, if the B<dyn_fields> attribute was
not provided, then a default set of header names will be provided
(C<'extra1'>, C<'extra2'>, ...) matching the number of extra fields
that are in the first (data) line.

By default, or if C<'auto'> was explicitly specified, the first
line is examined.  If it matches all of the fixed field names
(and the dyn_fields names if they were provided) then the line
is processed as if C<'check'> were specified.  However, if it
doesn't match, then the first line is treated as a data line
just as if C<'none'> had been specified.

=back

The B<comment> attribute can be set to a true value to enable
comment line stripping. Then, input lines which have a
comment symbol (C<#>) as the first non-blank character will not
generate an input record.  After each input record is generated,
the reader object method B<read_comments> that will return any
comment lines that preceeded that record.  After the end of the
stream has been reached (a undef was returned from the read method)
the B<read_comments> method will return any trailing comments that
followed the last data record.

You can also set the attribute B<comment_pattern> to provide a
regular expression pattern to be used to decide whether an input
line is comment or data.

There is a similar trio of attributes, B<pre_header>, B<pre_header_pattern>,
and B<pre_headers> that allow an additional type of comment to be
detected before the initial header (if there is one).  If pre_header
is set, then any line that matches the pre_header_pattern or the
comment_pattern before the actual header line will be ignored and saved.
All such lines will be returned by the pre_headers attribute.  If
pre_header is not set, but comment is set, then comment lines will still
be detected before the actual header line and be available with the
pre_headers attribute.

At present, there
is no support for trailing comments after data fields.  It can be
awkward to determine when a comment symbol is actually desired as
the content of an actual field value.  That gets especially tricky
to determine with dynamic fields.  Rather than use tricky coding,
and perhaps requiring escape characters in field values, it was
decided to only provide the minimal support.  If such comments are
permitted in the future, it will be enabled by setting the B<comment>
to B<2>, while full-line comments (without field comments) would
continue as at present with a setting of B<1>.

For Dyn readers, the B<dyn_fields> parameter can be passed to
specify the field names for the dynamic fields.  If so, they will
be validated (if header validation is enabled - either C<'check'>
or C<'auto'> for the B<header> attribute).

The B<extra_class_params> attribute accepts a ref to a list of
strings.  These will be passed to the I<new> method of the target
class when a set of values has been read.  This may be useful for
some target classes.  The only current use for this is for I<Dyn>
I<reader> objects - they can be given:

    extra_class_params => [ install_methods => 1 ],

to have dynamic fields be given accessor methods in the created
object.  (If you wish to do this, the definition of the target class
must not invoke the make_immutable method in the class definition.
Not using make_immutable, and the time to install these extra
attribute accessors on every object is somewhat time-consuming -
if you are writing code that knows about the names of the dynamic
fields, then perhaps they should instead be written as fixed fields.)

=head2 pre_headers

This attribute will return an array ref to the list of any pre_header
or comment lines that preceeded the header line in the input stream.

=head2 read

The B<read> method takes no arguments.  It reads the next line
(if any) from the handle, validates the fields, and retuns an
object of C<$class> with the field contents used to initialize
the attributes.  At end of file, it returns C<undef>.

=head2 read_comments

This attribute will return an array ref to the list of any comment
lines that preceeded the most recent record in the input stream
(but ony those that followed the previous record or the header or
the start of the stream).  After a read returns C<undef> to indicate
the end of the stream, this attribute will return any trailing
comments that followed the final record.

=head2 _croak

    $reader->_croak("error message");

The C<_croak> method is needed internally, but may also be useful
in some cases by the code that uses the reader.  It croaks with
the supplied message, appending the filename and line number.

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO::Reader::Fixed

=item BoutrosLab::TSVStream::IO::Reader::Dyn

These are the two classes of reader - which read streams containing
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

Describes the format of a text stream that a reader can read from.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

