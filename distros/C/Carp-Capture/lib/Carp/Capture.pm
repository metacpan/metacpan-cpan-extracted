package Carp::Capture;
use 5.010;
use warnings FATAL => 'all';
use strict;

use Carp::Proxy qw( fatal );
use English     qw( -no_match_vars );
use Moose;
use Readonly;

our $VERSION = '0.02';

Readonly::Scalar my $BUG_REPORT
    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Capture';

#----- The Boolean values pushed onto the 'capture_status' stack
Readonly::Scalar my $ENABLED  => 1;
Readonly::Scalar my $DISABLED => 0;

#----- The magic value returned when capturing has been disabled.
Readonly::Scalar my $UNCAPTURED => 0;

#----- We pack() uints to represent callstacks.  'I' maps to a C unsigned.
Readonly::Scalar my $ENCODING => 'I*';

#----- How many bytes are consumed by encoding a single unsigned?
Readonly::Scalar my $SIZEOF_UNSIGNED => length pack $ENCODING, 0;

#----- We harvest 3 components (Subr, Line and File) from caller().
Readonly::Scalar my $FRAME_COMPONENTS => 3;
Readonly::Scalar my $STACKFRAME_SIZE  => $FRAME_COMPONENTS * $SIZEOF_UNSIGNED;

#----- An association is an annotation id packed with a callstack id.
Readonly::Scalar my $ASSOCIATION_SIZE => 2 * $SIZEOF_UNSIGNED;

#----- For validation: id values are supposed to be unsigned integers
Readonly::Scalar my $UNSIGNED_REX => qr{ \A \d+ \z }x;

#----- Loathe Windows
Readonly::Scalar my $LINE_SEPARATOR => ($OSNAME =~ /MSWin/xi)
    ? "\r\n"
    : "\n";

#----- For indexing the list returned by caller()
Readonly::Scalar my $CALLER_FILENAME   => 1;
Readonly::Scalar my $CALLER_LINE       => 2;
Readonly::Scalar my $CALLER_SUBROUTINE => 3;

has 'components',
    (
     documentation  => q{ 'string => id' mapping for caller() components },
     is             => 'ro',
     isa            => 'HashRef',
     default        => sub{ {} },
    );

has 'callstacks',
    (
     documentation  => q{ 'string => id' mapping for packed callstacks },
     is             => 'ro',
     isa            => 'HashRef',
     default        => sub{ {} },
    );

has 'annotations',
    (
     documentation  => q{ 'id => scalar' mapping for annotations },
     is             => 'ro',
     isa            => 'ArrayRef',
     default        => sub{ [] },
     traits         => [qw( Array )],
     handles        =>
     {
      _anno_fetch   => 'get',
      _anno_next_id => 'count',
      _anno_store   => 'push',
     },
    );

has 'capture_status',
    (
     documentation  => q{ The capturing ENABLED/DISABLED stack },
     is             => 'rw',
     isa            => 'ArrayRef',
     default        => sub{ [$ENABLED] },
     traits         => [qw( Array )],
     handles        =>
     {
      status        => [ get  => -1        ],
      enable        => [ push => $ENABLED  ],
      disable       => [ push => $DISABLED ],
      _pop_status   => 'pop',
      _stack_depth  => 'count',
     },
    );

no Moose;
__PACKAGE__->meta->make_immutable();

#-----
# To capture a callstack we use Perl's caller(), in a loop.  Each stackframe
# reported by caller() contains three values of interest: the subroutine, the
# filename and the line number.  In effect we want to save a list of
# triplets, one triplet for each stackframe.
#
# The obvious choice would be an Array of three-element ArrayRefs, or maybe
# just a flat Array where the number of elements is a multiple of three.
# Unfortunately, Arrays of ArrayRefs of Scalars, or even just flat Arrays of
# Scalars, consume an apalling amount of storage.
#
# With an eye on minimizing storage we decide to use a hash (the 'components'
# attribute) to hold the subroutine name and filename strings returned by
# caller().  Filenames are likely to be reused within a single callstack, and
# subroutines are likely to be reused by different callstacks.  The hash
# stores one copy of a string as its key and assigns a unique integer as the
# value.
#
# Using the Components hash to map subroutines and filenames to integers
# makes all three of our frame components become integers.  The entire
# callstack, in fact, becomes a list of integers.  Using pack() we can
# convert a list of integers into a binary string.  The amount of storage
# required for this string is a small fraction of that required for an Array
# of Arrays, so we choose to internally represent callstacks as packstrings.
#
# We could return the packstring to the user, as the representation of their
# callstack.  Instead, we choose to employ the same strategy of hash-key
# storage with unique-integer identifier as value.  The 'callstacks'
# attribute is a hash that holds callstack packstrings as keys.  This means
# that the user is given a simple integer to track their callstack.
#
# There are two other reasons, besides binary avoidance at the user-level,
# for mapping packstrings with the Callstacks hash.  Repeated callstacks
# happen whenever capturing is requested from a loop.  By mapping callstacks
# we only have to store a repeated callstack once.  We can also help the user
# identify loop iterations by offering storage for an 'annotation' value.
#
# If the user provides an annotation then we will need to save a copy of it,
# which we do pushing it onto an array - the 'annotations' attribute.  The
# index of the new element becomes the annotation's id.
#
# We can't use the same (hash) strategy employed for components and pack
# strings because annotation values can be any kind of scalar including
# references and undefs; things that don't survive stringification needed for
# storage as hash keys.
#
# So, there is no redundancy avoidance mechanism for annotations, i.e.
# storage is not as efficient as it might be.  This is not a big deal because
# we expect that:
#   1) Most users won't even use annotations in the first place.
#   2) When annotations are supplied, they are likely to be different.
#
# We then combine the annotation_id and the callstack_id together in an
# Association data structure - another packstring.  The Association is then
# inserted in the 'callstacks' hash.  The 'callstacks' attribute stores BOTH
# callstacks and associations.  This is OK, because we can distinguish
# between callstack packstrings and association packstrings by their
# lengths.  Associations always contain 2 values, callstacks always contain
# 3N values.
#
# If a packstring pulled out of the Callstacks hash is of length 2 then we
# extract the first value for annotation id, or the second value for a
# callstack id.  The callstack id is then used to fetch another packstring,
# which will be the real callstack.
#
# Fetching a packstring from a hash, given the corresponding identifier
# value, is a slow, linear search.  We have to search through all the values
# until we find a match.  We accept this tradeoff because
#   1) Providing fast lookup from both directions (string->id AND id->string)
#      would double storage requirements.
#   2) Each capture would require two insertions and would therefore be slower.
#   3) If the user is retrieving a callstack for presentation as a
#      stacktrace then some kind of exception has probably happened and
#      performance is no longer that important.
#
# If you have followed all the above you may be questioning why not
# combine the 'components' attribute and 'callstacks' attribute into a single
# hash - they are both just string->id mappings.  You're right, this would
# work just fine, and it would save a very small amount of storage - one
# hash.  I decided against combining hashes because leaving them separate
# is somewhat safer.  If the user mangles an id they simply get the wrong
# callstack; they can't crash us by identifying a filename as a callstack.
#-----

sub capture {
    my $self = shift;

    return $UNCAPTURED
        if $self->status == $DISABLED;

    #-----
    # undef is a valid annotation.  Therefore we need to distinguish between
    # not providing an annotation argument and providing undef.
    #-----
    my( $annotation_provided, $annotation ) = (@_ > 0)
        ? ( 1, shift )
        : ( 0, undef );

    my $callstacks   = $self->callstacks;
    my $packstring   = _callstack_as_packstring( $self );
    my $callstack_id = _insert( $callstacks, $packstring );

    return $callstack_id
        if not $annotation_provided;

    my $annotation_id = $self->_anno_next_id;
    $self->_anno_store( $annotation );

    #-----
    # Alphabetical name ordering: Annotation_id, Callstack_id in the pack().
    #-----
    my $association    = pack $ENCODING, $annotation_id, $callstack_id;
    my $association_id = _insert( $callstacks, $association );

    return $association_id;
}

sub stacktrace {
    my( $self, $id ) = @_;

    fatal 'missing_identifier'
        if not defined $id;

    fatal 'invalid_identifier', $id
        if $id !~ $UNSIGNED_REX;

    return wantarray ? () : ''
        if $id == $UNCAPTURED;

    my @callstack;
    my $components = $self->components;
    my @ids = unpack $ENCODING, _fetch_callstack_packstring( $self, $id );
    while( @ids ) {

        #----- Alphabetical name order: File Line Subr
        my( $file_id, $line, $subr_id ) = splice @ids, 0, $FRAME_COMPONENTS;

        push @callstack,
            {
             file => _fetch_key_by_id( $components, $file_id ),
             line => $line,
             subr => _fetch_key_by_id( $components, $subr_id ),
            };
    }

    return @callstack
        if wantarray;

    my $stacktrace = '';

    foreach my $f ( @callstack ) {

        $stacktrace
            .= "\t"
            . $f->{subr} . ' called at '
            . $f->{file} . ' line '
            . $f->{line} . $LINE_SEPARATOR;
    }

    return $stacktrace;
}

sub revert {
    my( $self ) = @_;

    #----- Guard against excess popping: stack is never empty.
    $self->_pop_status
        if $self->_stack_depth > 1;

    return;
}

sub retrieve_annotation {
    my( $self, $id ) = @_;

    fatal 'missing_identifier'
        if not defined $id;

    fatal 'invalid_identifier', $id
        if $id !~ $UNSIGNED_REX;

    fatal 'uncaptured_annotation'
        if $id == $UNCAPTURED;

    my $packstring = _fetch_key_by_id( $self->callstacks, $id );

    fatal 'unannotated_capture', $id
        if $ASSOCIATION_SIZE != length $packstring;

    my( $annotation_id, $callstack_id ) = unpack $ENCODING, $packstring;

    return $self->_anno_fetch( $annotation_id );
}

sub uncaptured { return $UNCAPTURED; }

#-----
# <$cache> is expected to be a HashRef, by string, with unique integers for
# values.  Both the 'components' and 'callstacks' attributes fit this
# description, so we factored out the common functionality into this
# subroutine.
#
# Our task here is to return the integer corresponding to <$entry>.  If
# <$entry> does not exist then it is inserted using a value of one more than
# the previous number of elements in the hash.  In other words integers start
# at one and increment upwards.
#-----
sub _insert {
    my( $cache, $entry ) = @_;

    return $cache->{ $entry }
        if exists $cache->{ $entry };

    #----- Start at 1;  We reserve the id of 0 to represent 'Uncaptured'
    my $id = 1 + keys %{ $cache };

    $cache->{ $entry } = $id;

    return $id;
}

sub _fetch_key_by_id {
    my( $cache, $id ) = @_;

    #----- Void-context keys() resets each() traversal.
    keys %{ $cache };

    my $match;
    my( $key, $val );
    while( ($key,$val) = each %{ $cache } ) {    #----- Yup, linear search

        next
            if $val != $id;

        $match = $key;
        last;
    }

    fatal 'no_such_id', $cache, $id
        if not defined $match;

    return $match;
}

sub _callstack_as_packstring {
    my( $self ) = @_;

    #----- Hash for subroutine and filename strings
    my $components = $self->components;

    my $triplets = '';

    #-----
    # What we really want is the callstack as seen from _our_ caller.
    # Start with frame #1
    #-----
    for( my $frame=1;   1;   ++$frame ) {

        my( $filename, $line, $subr ) =
            (caller $frame)[ $CALLER_FILENAME,
                             $CALLER_LINE,
                             $CALLER_SUBROUTINE ];

        #----- caller() returns an empty list at the end of the callstack
        last
            if not defined $filename;

        #----- Alphabetic name order: Filename, Line, Subroutine
        $triplets .=
            pack $ENCODING,
            _insert( $components, $filename ),
            $line,
            _insert( $components, $subr );
    }

    return $triplets;
}

sub _fetch_callstack_packstring {
    my( $self, $id ) = @_;

    my $callstacks = $self->callstacks;
    my $packstring = _fetch_key_by_id( $callstacks, $id );
    my $len        = length $packstring;

    #-----
    # The 'callstacks' attribute stores two types of pack() strings in its
    # keys: 2-value associations, OR 3*N - value callstacks.  If the
    # retrieved key is a multiple of three unsigneds in length then this must
    # be a callstack.
    #-----
    return $packstring
        if 0 == $len % $STACKFRAME_SIZE;

    #----- Something is deeply wrong if this doesn't look like an association.
    fatal 'incorrect_entry_size', $len, $id
        if $len != $ASSOCIATION_SIZE;

    #-----
    # As association is just an annotation id  and a callstack id packed
    # together.  This means we need to unpack to get the callstack id
    # out of the pair, then perform another lookup to get the callstack.
    #-----
    my( $annotation_id, $callstack_id ) = unpack $ENCODING, $packstring;

    return _fetch_key_by_id( $callstacks, $callstack_id );
}

#----- Fatal handlers

sub _cp_incorrect_entry_size {
    my( $cp, $len ) = @_;

    $cp->filled(<<"EOF");
The system has encountered corruption in the data structure used to capture
stacktraces.  The lookup was successful, but the entry has an unexpected
length.  This is a defect; you should complain!
EOF

    $cp->fixed( $BUG_REPORT, 'Defect reporting URL' );

    $cp->fixed(<<"EOF", 'Details' );
length          $len
sizeof_unsigned $SIZEOF_UNSIGNED
EOF
    return;
}

sub _cp_invalid_identifier {
    my( $cp, $id ) = @_;

    $cp->filled( <<"EOF" );
The '\$id' argument, '$id', is not of the correct form for a callstack
identifier.  Identifiers are expected to be integers.
EOF
    $cp->usage;
    return;
}

sub _cp_missing_identifier {
    my( $cp, $id ) = @_;

    $cp->filled( 'The identifier argument, $id, is missing or undef.' );
    $cp->usage;
    return;
}

sub _cp_no_such_id {
    my( $cp, $cache, $id ) = @_;

    my $count = keys %{ $cache };

    my $msg = <<"EOF";
The callstack capturing database does not contain an identifier
matching '$id'.
EOF

    $msg .= $count > 0
        ? "The database has $count other entries."
        : 'The database is empty.';

    $cp->filled( $msg );
    return;
}

sub _cp_unannotated_capture {
    my( $cp, $id ) = @_;

    $cp->filled(<<"EOF");
The identifier '$id' corresponds to a callstack that was captured
WITHOUT an annotation.  You can still obtain a stacktrace, but there
is no annotation to retrieve.
EOF
    return;
}


sub _cp_uncaptured_annotation {
    my( $cp ) = @_;

    $cp->filled(<<"EOF");
The callstack identifier indicates that capturing was currently
DISABLED when callstack_capture() was invoked.  Neither the callstack
nor the annotation was stored, so there is nothing to retrieve.
EOF
    return;
}

sub _cp_usage_retrieve_annotation {
    my( $cp ) = @_;

    $cp->synopsis( -verbose  => 99,
                   -sections => ['METHODS/retrieve_annotation'],
                 );

    return;
}

sub _cp_usage_stacktrace {
    my( $cp ) = @_;

    $cp->synopsis( -verbose  => 99,
                   -sections => ['METHODS/stacktrace'],
                 );

    return;
}


1; # End of Carp::Capture

__END__

=pod

=begin stopwords

AnnoCPAN
API
callstack
CPAN
filename
HashRef
Hashrefs
HashRefs
initializer
Liebert
multi
perldoc
stackframe
stacktrace
subr
uncaptured

=end stopwords

=head1 NAME

Carp::Capture - Capture callstacks for later presentation.

=head1 SYNOPSIS

    use Carp::Capture;

    my $cc = Carp::Capture->new();
    my $id = $cc->capture;
    ...
    print scalar $cc->stacktrace( $id );

=head1 DESCRIPTION

Perl's standard library module B<Carp> provides the B<confess()>
function.  B<Carp::confess()> throws an exception containing a
stacktrace.  Stacktraces can be valuable debugging aids by describing
where an exception happened and how the program got there.
B<Carp::Capture> does not throw exceptions.  Instead, it separates the
capturing of a callstack, from its presentation as a stacktrace.

A B<Carp::Capture> object holds compact representations of captured
callstacks.  An integer identifier is returned each time capturing is
requested.  The identifier can be used to produce a stacktrace.

The need for callstack capturing came about during the development of
a compiler application.  Several types of user errors could not be
detected at specification time (during API calls).  Conflicts revealed
themselves only after the specifications began to execute.  By tagging
each specification with a captured callstack we were able to pinpoint
conflict origins, back in user code.

=head1 CALLSTACK-CAPTURING

Invoking L<capture()|/capture> initiates stack traversal, using Perl's
B<caller()>.  The subroutine, line number and filename components of
each stackframe are harvested from the B<caller()> result.  The chain
of harvested frames is stored in the B<Carp::Capture> object.  An
integer identifier is returned for future reference of the captured
callstack.

=head1 SELECTIVE-CAPTURE

The module attempts to be fast and to use minimal storage.  That being
said, each capture takes time and consumes space.  Sections of code
that are not under suspicion can disable capturing.

B<Carp::Capture> provides a stack mechanism for enabling and disabling
callstack captures.  When the top of the stack indicates that
capturing is disabled, calls to L<capture()|/capture> return
immediately.  In this case, the returned identifier is a constant that
indicates an 'uncaptured' callstack.

Capturing can be dynamically enabled and disabled with
L<enable()|/enable> and L<disable()|/disable>.  These methods push new
values onto an internal stack.  The L<revert()|/revert> method pops
the stack, restoring capture status to whatever it was before the most
recent push.

Capture status is B<enabled> when the object is first constructed.

=head1 STACKTRACE-RENDERING

A stacktrace, in string form, can be produced by invoking
L<stacktrace()|/stacktrace> in a scalar context.  The result is a
string, with one line for each stackframe, similar to
B<Carp::confess()>:

    <TAB><subr1>() called at <file1> line <line1>
    <TAB><subr2>() called at <file2> line <line2>
    ...

The data fields of B<subr>, B<file> and B<line> are also available in
raw form to support user-designed formatting.  In list context, the
L<stacktrace()|/stacktrace> method returns a list of HashRefs.  Each
HashRef has three keys: B<subr>, B<file> and B<line>.  There is one
HashRef for each stackframe, with the first HashRef corresponding to
the innermost subroutine call.

Attempting to produce a stacktrace from an 'uncaptured' identifier
results in an empty string from L<stacktrace()|/stacktrace>, or an
empty list from L<stacktrace()|/stacktrace>.

=head1 DISAMBIGUATION

If L<capture()|/capture> is invoked from within a loop then the
callstack is the same for each iteration and hence the returned
identifiers will all be the same as well.

    my $cc = Carp::Capture->new;
    my @ids;

    foreach my $letter (qw( a b c d )) {

        push @ids, $cc->capture;
    }

    # Prints "1 1 1 1"
    say "@ids";

L<capture()|/capture> accepts an optional argument, called an
B<annotation>, to help distinguish one iteration from another.

A common tactic is to provide the loop iteration value as the
annotation, but any scalar is acceptable.

If an annotation is provided to L<capture()|/capture> then a copy of
the annotation will be stored inside the B<Carp::Capture> object.
Returned identifiers will be always be unique when an annotation is
provided.

Use L<retrieve_annotation()|/retrieve_annotation> to fetch the stored
annotation.

    my $cc = Carp::Capture->new;
    my @ids;

    foreach my $letter (qw( a b c d )) {

        push @ids, $cc->capture( $letter );
    }

    # Prints "2 3 4 5"
    say "@ids";

    # Prints "True"
    say "True"
        if $cc->stacktrace( $ids[0] ) eq
           $cc->stacktrace( $ids[1] );

    # Prints "c"
    say $cc->retrieve_annotation( $ids[2] );

=head1 EXPORTS

None.

=head1 METHODS

In the descriptions below, B<$cc> refers to a B<Carp::Capture> object
returned by L<new()|/new>.  B<$id> refers to the identifier returned
by L<capture()|/capture>.  Return value types are shown in angle
brackets, like B<E<lt>voidE<gt>>.

=head2 new

 Usage:
    $cc = Carp::Capture->new();

B<new()> creates the object that holds stackframe components, callstack
representations and the capture-status stack.  All attributes are
private so there are no initializer arguments.

=head2 capture

 Usage:
    $id = $cc->capture;
    -or-
    $id = $cc->capture( $annotation );

The B<capture()> method traverses the current callstack and harvests
stackframe components along the way.  The data is stored in the I<$cc>
object.  The return value, an integer, identifies the internal
representation of the captured callstack.

If capturing has been disabled (See
L<SELECTIVE-CAPTURE|/SELECTIVE-CAPTURE>) then the returned integer
is a constant that represents an uncaptured stack.

The I<$annotation> argument is optional.  If I<$annotation> is
provided then I<$annotation> is captured along with the callstack.
The intent is to distinguish similar callstacks, such as might be
captured from within a loop.  See L<DISAMBIGUATION|/DISAMBIGUATION>.

=head2 stacktrace

 Usage:
    <String> = $cc->stacktrace( $id );
    -or-
    <ListOfHashRefs> = $cc->stacktrace( $id );

In Scalar Context, B<stacktrace()> returns a string representation
of the callstack corresponding to the callstack identified by
I<$id>.

There is one line in the returned string for each stackframe in the
captured callstack.  Stack frames are ordered from the innermost outward,
just like B<Carp::confess>.  Lines are of the form:

    <TAB><subroutine> called at <file> line <line>

In List Context, B<stacktrace()> returns callstack components as a
data structure.  The callstack identified by I<$id>, is returned as a
list of HashRefs.  There is one element in the list for each frame in
the captured callstack.  Stack frames are ordered from the innermost
outward, just like B<Carp::confess>.  Each HashRef element has three
keys: B<'file'>, B<'line'> and B<'subr'>.

If I<$id> identifies the 'uncaptured' callstack (See
L<SELECTIVE-CAPTURING|/SELECTIVE-CAPTURING>) then nothing was captured.
In Scalar Context, the empty string will be returned.  In List Context
an empty list will be returned.

=head2 enable

 Usage:
    <void> $cc->enable;

B<Carp::Capture> objects maintain an internal stack that controls whether
capturing is performed.  B<enable()> pushes a new 'Enabled' value on top
of the stack.

Invoking L<revert()|/revert> restores capture status to
whatever it was before the last push.  Capturing starts out as 'Enabled'.

=head2 disable

 Usage:
    <void> $cc->disable;

B<Carp::Capture> objects maintain an internal stack that controls
whether capturing is performed.  B<disable()> pushes a new 'Disabled'
value on top of the stack.

Invoking L<revert()|/revert> restores capture status to whatever it
was before the last push.  Capturing starts out as 'Enabled'.

=head2 revert

 Usage:
    <void> $cc->revert;

B<Carp::Capture> objects maintain an internal stack that controls
whether capturing is performed.  B<revert()> pops and discards the
current capture status.  The previous status is restored.

=head2 retrieve_annotation

 Usage:
    <Scalar> = $cc->retrieve_annotation( $id );

If an annotation value was provided in the call to
L<capture()|/capture> then it can be retrieved with the
same identifier used to generate stacktraces.

An exception is thrown if I<$id> originated from a capture that was disabled,
or from one in which no annotation was provided.

=head2 uncaptured

 Usage:
    <Integer> = $cc->uncaptured;

The magic value used to indicate that no callstack was captured, is returned
by B<uncaptured()>.  Testing an identifier for equality with the Uncaptured
value is a way to query the identifier's status.

    my $cc = Carp::Capture->new;
    my $uncaptured = $cc->uncaptured;

    # Prints "On"
    say $uncaptured == $cc->capture ? 'Off' : 'On';

    $cc->disable;

    # Prints "Off"
    say $uncaptured == $cc->capture ? 'Off' : 'On';

The Uncaptured value might also be useful as a default in a data structure.
Capturing can be gated with a conditional that overwrites the default when
active.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-carp-capture at
rt.cpan.org>, or through the web interface at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-Capture>.

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Carp::Capture

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Capture>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Capture>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Capture>

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Capture/>

=back

=head1 DEPENDENCIES

All of these are available from CPAN:

 Moose
 Carp::Proxy

=head1 SEE ALSO

=over 4

=item *

See 'perldoc -f caller' for information on accessing the current callstack
from Perl.

=item *

See 'perldoc Carp' for documentation on B<confess()>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2015 Paul Liebert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
