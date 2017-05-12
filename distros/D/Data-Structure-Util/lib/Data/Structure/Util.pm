package Data::Structure::Util;

use 5.008;

use strict;
use warnings::register;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Storable qw( freeze );
use Digest::MD5 qw( md5_hex );

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw( Exporter DynaLoader );

$VERSION = '0.16';

@EXPORT_OK = qw(
  unbless get_blessed get_refs has_circular_ref circular_off signature
);

if ( $] >= 5.008 ) {
    push @EXPORT_OK, qw(
      has_utf8 utf8_off utf8_on _utf8_on _utf8_off
    );
}

bootstrap Data::Structure::Util $VERSION;

sub has_utf8 {
    has_utf8_xs( $_[0] ) ? $_[0] : undef;
}

sub utf8_off {
    utf8_off_xs( $_[0] ) ? $_[0] : undef;
}

sub utf8_on {
    utf8_on_xs( $_[0] ) ? $_[0] : undef;
}

sub _utf8_off {
    _utf8_off_xs( $_[0] ) ? $_[0] : undef;
}

sub _utf8_on {
    _utf8_on_xs( $_[0] ) ? $_[0] : undef;
}

sub unbless {
    unbless_xs( $_[0] );
}

sub get_blessed {
    $_[0] or return [];
    get_blessed_xs( $_[0] );
}

sub get_refs {
    $_[0] or return [];
    get_refs_xs( $_[0] );
}

sub has_circular_ref {
    $_[0] or return $_[0];
    has_circular_ref_xs( $_[0] );
}

# Need to hold another reference to the passed in value to avoid this
# pathological case throwing an error
#  my $obj8 = [];
#  $obj8->[0] = \$obj8;
#  circular_off($obj8); # Used to throw an error

sub circular_off {
    my $r = $_[0];
    $r or return $r;
    circular_off_xs( $r );
}

sub signature {
    return @_
      ? md5_hex( freeze( [ $_[0], signature_xs( $_[0] ) ] ) )
      : '0' x 32;
}

1;

__END__

=head1 NAME

Data::Structure::Util - Change nature of data within a structure

=head1 SYNOPSIS

    use Data::Structure::Util qw(
      has_utf8 utf8_off utf8_on unbless get_blessed get_refs
      has_circular_ref circular_off signature
    );

    # get the objects in the data structure
    my $objects_arrayref = get_blessed( $data );

    # unbless all objects
    unbless( $data );

    if ( has_circular_ref( $data ) ) {
        print "Removing circular ref!\n";
        circular_off( $data );
    }

    # convert back to latin1 if needed and possible
    utf8_off( $data ) if defined has_utf8( $data );

=head1 DESCRIPTION

C<Data::Structure::Util> is a toolbox to manipulate the data inside a
data structure. It can process an entire tree and perform the operation
requested on each appropriate element.

For example: It can transform all strings within a data structure to
utf8 or transform any utf8 string back to the default encoding. It can
remove the blessing on any reference. It can collect all the objects or
detect if there is a circular reference.

It is written in C for decent speed.

=head1 FUNCTIONS

All Data::Structure::Util functions operate on a whole tree. If you pass
them a simple scalar then they will operate on that one scalar. However,
if you pass them a reference to a hash, array, or scalar then they will
iterate though that structure and apply the manipulation to all
elements, and in turn if they are references to hashes, arrays or
scalars to all their elements and so on, recursively.

For speed reasons all manipulations that alter the data structure do in-
place manipulation meaning that rather than returning an altered copy of
the data structure the passed data structure which has been altered.

=head2 Manipulating Data Structures

=over 4

=item has_circular_ref($ref)

This function detects if the passed data structure has a circular
reference, that is to say if it is possible by following references
contained in the structure to return to a part of the data structure you
have already visited. Data structures that have circular references will
not be automatically reclaimed by Perl's garbage collector.

If a circular reference is detected the function returns a reference
to an element within circuit, otherwise the function will return a
false value.

If the version of perl that you are using supports weak references then
any weak references found within the data structure will not be
traversed, meaning that circular references that have had links
successfully weakened will not be returned by this function.

=item circular_off($ref)

Detects circular references in $ref (as above) and weakens a link in
each so that they can be properly garbage collected when no external
references to the data structure are left.

This means that one (or more) of the references in the data structure
will be told that the should not count towards reference counting. You
should be aware that if you later modify the data structure and leave
parts of it only 'accessible' via weakened references that those parts
of the data structure will be immediately garbage collected as the
weakened references will not be strong enough to maintain the connection
on their own.

The number of references weakened is returned.

=item get_refs($ref)

Examine the data structure and return a reference to flat array that
contains one copy of every reference in the data structure you passed.

For example:

    my $foo = {
        first  => [ "inner", "array", { inmost => "hash" } ],
        second => \"refed scalar",
    };

    use Data::Dumper;
    # tell Data::Dumper to show nodes multiple times
    $Data::Dumper::Deepcopy = 1;
    print Dumper get_refs( $foo );

    $VAR1 = [
        { 'inmost' => 'hash' },
        [ 'inner', 'array', { 'inmost' => 'hash' } ],
        \'refed scalar',
        {
            'first'  => [ 'inner', { 'inmost' => 'hash' }, 'array' ],
            'second' => \'refed scalar'
        }
    ];

As you can see, the data structure is traversed depth first, so the
top most references should be the last elements of the array.  See
L<get_blessed($ref)> below for a similar function for blessed objects.

=item signature($ref)

Returns a md5 of the passed data structure.  Any change at all to the
data structure will cause a different md5 to be returned.

The function examines the structure, addresses, value types and flags
to generate the signature, meaning that even data structures that
would look identical when dumped with Data::Dumper produce different
signatures:

    $ref1 = { key1 => [] };

    $ref2 = $ref1;
    $ref2->{key1} = [];

    # this produces the same result, as they look the same
    # even though they are different data structures
    use Data::Dumper;
    use Digest::MD5 qw(md5_hex);
    print md5_hex( Dumper( $ref1 ) ), " ", md5_hex( Dumper( $ref2 ) ), "\n";
    # cb55d41da284a5869a0401bb65ab74c1 cb55d41da284a5869a0401bb65ab74c1

    # this produces differing results
    use Data::Structure::Util qw(signature);
    print signature( $ref1 ), " ", signature( $ref2 ), "\n";
    # 5d20c5e81a53b2be90521167aefed9db 8b4cba2cbae0fec4bab263e9866d3911

=back

=head2 Object Blessing

=over 4

=item unbless($ref)

Remove the blessing from any objects found within the passed data
structure. For example:

    my $foo = {
        'a' => bless( { 'b' => bless( {}, "c" ), }, "d" ),
        'e' => [ bless( [], "f" ), bless( [], "g" ), ]
    };

    use Data::Dumper;
    use Data::Structure::Util qw(unbless);
    print Dumper( unbless( $foo ) );

    $VAR1 = {
        'a' => { 'b' => {} },
        'e' => [ [], [] ]
    };

Note that the structure looks inside blessed objects for other
objects to unbless.

=item get_blessed($ref)

Examine the data structure and return a reference to flat array that
contains every object in the data structure you passed.  For example:

    my $foo = {
        'a' => bless( { 'b' => bless( {}, "c" ), }, "d" ),
        'e' => [ bless( [], "f" ), bless( [], "g" ), ]
    };

    use Data::Dumper;
    # tell Data::Dumper to show nodes multiple times
    $Data::Dumper::Deepcopy = 1;
    use Data::Structure::Util qw(get_blessed);
    print Dumper( get_blessed( $foo ) );

    $VAR1 = [
        bless( {}, 'c' ),
        bless( { 'b' => bless( {}, 'c' ) }, 'd' ),
        bless( [], 'f' ),
        bless( [], 'g' )
    ];

This function is essentially the same as C<get_refs> but only returns
blessed objects rather than all objects.  As with that function the
data structure is traversed depth first, so the top most objects
should be the last elements of the array.  Note also (as shown in the
above example shows) that objects within objects are returned.

=back

=head2 utf8 Manipulation Functions

These functions allow you to manipulate the state of the utf8 flags in
the scalars contained in the data structure.  Information on the utf8
flag and it's significance can be found in L<Encode>.

=over 4

=item has_utf8($var)

Returns C<$var> if the utf8 flag is enabled for C<$var> or any scalar
that a data structure passed in C<$var> contains.

    print "this will be printed"  if defined has_utf8( "\x{1234}" );
    print "this won't be printed" if defined has_utf8( "foo bar" );

Note that you should not check the truth of the return value of this
function when calling it with a single scalar as it is possible to
have a string "0" or "" for which the utf8 flag set; Since C<undef>
can never have the utf8 flag set the function will never return a
defined value if the data structure does not contain a utf8 flagged
scalar.

=item _utf8_off($var)

Recursively disables the utf8 flag on all scalars within $var.  This
is the same the C<_utf8_off> function of L<Encode> but applies to any
string within C<$var>.  The data structure is converted in-place, and
as a convenience the passed variable is returned from the function.

This function makes no attempt to do any character set conversion to
the strings stored in any of the scalars in the passed data structure.
This means that if perl was internally storing any character as
sequence of bytes in the utf8 encoding each byte in that sequence will
then be henceforth treated as a character in it's own right.

For example:

    my $emoticons = { smile => "\x{236a}" };
    use Data::Structure::Util qw(_utf8_on);
    print length( $emoticons->{smile} ), "\n";    # prints 1
    _utf8_off( $emoticons );
    print length( $emoticons->{smile} ), "\n";    # prints 3

=item _utf8_on($var)

Recursively enables the utf8 flag on all scalars within $var.  This is
the same the C<_utf8_on> function of L<Encode> but applies to any
string within C<$var>. The data structure is converted in-place and as
a convenience the passed variable is returned from the function.

As above, this makes no attempt to do any character set conversion
meaning that unless your string contains the valid utf8 byte sequences
for the characters you want you are in trouble.  B<In some cases
incorrect byte sequences can segfault perl>.  In particular, the
regular expression engine has significant problems with invalid utf8
that has been incorrectly marked as utf8.  You should know what you
are doing if you are using this function; Consider using the Encode
module as an alternative.

Contrary example to the above:

    my $emoticons = { smile => "\342\230\272" };
    use Data::Structure::Util qw(_utf8_on);
    print length( $emoticons->{smile} ), "\n";    # prints 3
    _utf8_on( $emoticons );
    print length( $emoticons->{smile} ), "\n";    # prints 1

=item utf8_on($var)

This routine performs a C<sv_utf8_upgrade> on each scalar string in
the passed data structure that does not have the utf8 flag turned on.
This will cause the perl to change the method it uses internally to
store the string from the native encoding (normally Latin-1 unless
locales come into effect) into a utf8 encoding and set the utf8 flag
for that scalar.  This means that single byte letters will now be
represented by multi-byte sequences.  However, as long as the C<use
bytes> pragma is not in effect the string will be the same length as
because as far as perl is concerned the string still contains the same
number of characters (but not bytes).

This routine is significantly different from C<_utf8_on>; That routine
assumes that your string is encoded in utf8 but was marked (wrongly)
in the native encoding.  This routine assumes that your string is
encoded in the native encoding and is marked that way, but you'd
rather it be encoded and marked as utf8.

=item utf8_off($var)

This routine performs a C<sv_utf8_downgrade> on each scalar string in
the passed data structure that has the utf8 flag turned on.  This will
cause the perl to change the method it uses internally to store the
string from the utf8 encoding into a the native encoding (normally
Latin-1 unless locales are used) and disable the utf8 flag for that
scalar.  This means that multiple byte sequences that represent a
single character will be replaced by one byte per character. However,
as long as the C<use bytes> pragma is not in effect the string will be
the same length as because as far as perl is concerned the string
still contains the same number of characters (but not bytes).

Please note that not all strings can be converted from utf8 to the
native encoding; In the case that the utf8 character has no
corresponding character in the native encoding Perl will die with
"Wide character in subroutine entry" exception.

This routine is significantly different from C<_utf8_off>; That
routine assumes that your string is encoded in utf8 and that you want
to simply mark it as being in the native encoding so that perl will
treat every byte that makes up the character sequences as a character
in it's own right in the native encoding.  This routine assumes that
your string is encoded in utf8, but you want it each character that is
currently represented by multi-byte strings to be replaced by the
single byte representation of the same character.

=back

=head1 SEE ALSO

L<Encode>, L<Scalar::Util>, L<Devel::Leak>, L<Devel::LeakTrace>

See the excellent article
http://www.perl.com/pub/a/2002/08/07/proxyobject.html from Matt
Sergeant for more info on circular references.

=head1 REPOSITORY

https://github.com/AndyA/Data--Structure--Util

=head1 BUGS

C<signature()> is sensitive to the hash randomisation algorithm

This module only recurses through basic hashes, lists and scalar
references.  It doesn't attempt anything more complicated.

=head1 THANKS TO

James Duncan and Arthur Bergman who helped me and found a name for
this module.  Leon Brocard and Richard Clamp have provided invaluable
help to debug this module.  Mark Fowler rewrote large chunks of the
documentation and patched a few bugs.

=head1 AUTHOR

This release by Andy Armstrong <andy@hexten.net>

Originally by Pierre Denis <pdenis@fotango.com>

http://opensource.fotango.com/

=head1 COPYRIGHT

Copyright 2003, 2004 Fotango - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
