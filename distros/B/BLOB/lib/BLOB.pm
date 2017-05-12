package BLOB;
use strict;
use Carp qw(carp);
use Exporter ();

# No "our" in Perl 5.0
use vars qw(@ISA $VERSION @EXPORT);

$VERSION = '1.01';
@ISA     = qw(Exporter);
@EXPORT  = qw(mark_blob is_blob);

# Fallback for Perl < 5.8
*utf8::downgrade = sub { 1 } if not defined &utf8::downgrade;

# Class method
sub mark {
    my $class = shift;
    my $blob_ref = \shift;
    if (not utf8::downgrade($$blob_ref, 1)) {
        carp "Wide character outside byte range in BLOB, encoding data with UTF-8";
        utf8::encode($$blob_ref);
    }
    bless $blob_ref, $class;
}

# Function
sub mark_blob {
    BLOB->mark($_[0]);
}

# Function
sub is_blob {
    my $blob_ref = \shift;
    return undef if not eval { $blob_ref->isa('BLOB') };
    if (not utf8::downgrade($$blob_ref, 1)) {
        carp "Wide character outside byte range in BLOB, encoding data with UTF-8";
        utf8::encode($$blob_ref);
    }
    return 1;
}

1;

__END__

=head1 NAME

BLOB - Perl extension for explicitly marking binary strings

=head1 SYNOPSIS

    use BLOB;

    mark_blob($jpeg_data);

    if (is_blob $jpeg_data) {
        ...
    } else {
        ...
    }

    my $bytes = is_blob($foo) ? $foo : encode_utf8($foo);

=head1 DESCRIPTION

In general it is better if text operations and binary operations are separated
into different functions.

But sometimes a single function needs to support both text strings and binary
strings. Because the two string types are fundamentally different, it may be
necessary for the function to know what it is dealing with.

This package aims to be B<the> single way of indicating that a string is
binary, not text. Now CPAN module authors don't have to reinvent this wheel,
and module users do not have to learn a plethora of different syntaxes.

The name F<BLOB> historically stands for Binary Large OBject, but small strings
are of course also supported.

BLOB supports Perl versions all the way back to 5.0 and has no external
dependencies.

=head1 FUNCTION INTERFACE

The function interface provides the basic interface. The following functions
are provided by this module and exported by default:

=over 4

=item mark_blob($string)

Marks the string as a blob. The string can be used as before; it should be safe
to mark strings as blobs in existing code.

Note that a copy of a blob is not marked automatically.

=item is_blob($string)

Returns true if the string is a blob, false if the string is not a blob.

=back

=head1 OBJECT INTERFACE

The function interface provides basic functionality, but no means of extension.
With the object interface, class inheritance can be used to provide additional
functionality.

To use a BLOB as an object, use the special syntax C<(\$blob)>. Because $blob
remains a normal variable that can be used like any other string, the C<\> is
needed to indicate that you're going to use it as an object.

Before using a BLOB as an object, test that it actually is a blob with the
C<is_blob> function, because a normal non-BLOB string cannot be used as an object.

    if (is_blob $foo) {
        (\$foo)->method(...);
        # Without the is_blob test, this would fail if $foo is a normal string
    }

=over 4

=item BLOB->mark($string)

This is the same as mark_blob, but extensible with subtypes. It is possible
that a certain kind of BLOB has a constructor (typically called C<new>) instead
of C<mark>.

Blesses C<$string> and returns a reference to it.

=item (\$string)->isa($class)

(Inherited from UNIVERSAL.) Returns true if the BLOB belongs to a certain
class.

=item (\$string)->can($method)

(Inherited from UNIVERSAL.) Returns a code reference to the method if it is
supported, or undef otherwise.

=back

The base BLOB implementation does not provide any object methods except those
provided by Perl's UNIVERSAL class. Decorated BLOBs might provide additional
methods.

=head1 USING ALIASING

There are two compelling reasons to use aliasing techniques with blobs, instead
of copying the values like normal variable assignment does. One is that blobs
can get very large, and copying large values imposes a big memory and
performance penalty. The other is that the indication that something is a blob,
as set by C<mark_blob> or C<< BLOB->mark >>, is not retained in a copy.

There are several ways of addressing the actual variable instead of copying it:

=over 4

=item Use the alias in the @_ array.

    my ($self, undef, $arg_2) = @_;
    if (is_blob $_[1]) { ... }

=item Use Data::Alias

    alias my ($self, $string, $arg_2) = @_;
    if (is_blob $string) { ... }

=item Use a reference to the alias in @_

    my ($self, undef, $arg_2) = @_;
    my $string_ref = \$_[1];
    if (is_blob $$string_ref) { ... }

=item Require that the variable is passed with an explicit reference

    my ($self, $$string_ref, $arg_2) = @_;
    if (is_blob $$string_ref) { ... }

=back

In any case, the following won't work:

    my ($self, $string, $arg_2) = @_;
    if (is_blob $string) { ... }

This does not work because C<$string> is a copy, and copies don't automatically
get the BLOB mark.
=head1 PROGRAMMING LOGIC ERRORS

Byte operations should be separated from text operations in programming, with
only explicit conversion (through decoding and encoding) allowed between them.

Perl programmers who fail to do this, might end up with characters greater than
255 in their byte strings. Because a byte can only store a value in the 0..255
range, a string with a character greater than 255 cannot be used as a byte
string.

Also, for efficiency and compatibility with older Perl modules, the functions
provided by this module downgrade strings to ensure that the internal
representation is a raw octet sequence.

=head1 DIAGNOSTICS

This module can produce the following warnings:

=over 4

=item Wide character outside byte range in BLOB, encoding data with UTF-8

A string with at least one character greater than 255 was marked as BLOB.
Because a byte cannot hold a value greater than 255, the string was changed to
its UTF-8 encoding to allow further binary data processing.

Find out why this character got into this string, and repair the programming
logic error.

=back

If the warning is reported in the module you are using, set $Carp::Verbose = 1
for a stack trace.

=head1 CAVEATS

Marking as a BLOB is done by blessing the string. Do not bless the string
again. Blessing existing binary strings is extremely uncommon, but not
impossible.

=head1 TO DO

=over 0

=item * It would be nice if BLOB would intercept internal string encoding
upgrades, and downgrade immediately. This would allow a warning to be emitted
at the point where the source of the problem is, making debugging unintended
text+binary concatenations easier.

=item * Compose a document that describes the best practices for documenting
modules that specifically support marked blobs.

=back

=head1 AUTHOR

Juerd Waalboer <#####@juerd.nl>

=cut
