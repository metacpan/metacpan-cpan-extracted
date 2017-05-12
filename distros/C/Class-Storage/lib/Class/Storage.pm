package Class::Storage;

# See perldoc at bottom of this file

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.03';

use Scalar::Util qw(blessed reftype);

use base qw(Exporter);
our @EXPORT_OK = qw(packObjects unpackObjects);

use constant DEFAULT_TO_PACKED_METHOD_NAME => "TO_PACKED";
use constant DEFAULT_FROM_PACKED_METHOD_NAME => "FROM_PACKED";

# MooseX::Storage uses __CLASS__ and so it is perhaps a good idea not to choose
# *exactly* the same magic string - then it isn't magic any more! :-)
use constant DEFAULT_MAGIC_STRING => "__class__";

sub packObjects {
    my ($data, %options) = @_;

    _setDefaultOptions(\%options);

    my $val = _packObjects($data, \%options);
    return $val // $data;
}

sub _packObjects {
    my ($data, $options) = @_;

    my $toPackedMethodName = $options->{toPackedMethodName};

    if (blessed $data && $data->can($toPackedMethodName)) {
        my $packed = $data->$toPackedMethodName();
        bless $packed, ref($data);
        $data = $packed;
    }

    if (reftype $data) {
        if (reftype $data eq 'HASH') {
            return _packObjectsHash($data, $options);
        } elsif (reftype $data eq 'ARRAY') {
            return _packObjectsArray($data, $options);
        }
    }

    return undef;
}

sub _packObjectsHash {
    my ($hash, $options) = @_;
    # use Dbug; dbugDump(['hash', $hash]);
    foreach my $key (keys %$hash) {
        my $val = $hash->{$key};
        my $newVal = _packObjects($val, $options);
        if ($newVal) {
            $hash->{$key} = $newVal;
        }
    }
    if (blessed $hash) {
        $hash = {
            ( $options->{magicString} ?
                ( $options->{magicString} => ref($hash) ) : ()),
            %$hash
        };
    }
    return $hash;
}

sub _packObjectsArray {
    my ($array, $options) = @_;
    # use Dbug; dbugDump(['array', $array]);
    foreach my $index (0..$#$array) {
        my $val = $array->[$index];
        my $newVal = _packObjects($val, $options);
        if ($newVal) {
            $array->[$index] = $newVal;
        }
    }
    if (blessed $array) {
        $array = [
            ( $options->{magicString} ?
                ( $options->{magicString} => ref($array) ) : ()),
            @$array
        ];
    }
    return $array;
}

sub unpackObjects {
    my ($data, %options) = @_;
    _setDefaultOptions(\%options);
    my $val = _unpackObjects($data, \%options);
    return $val // $data;
}

sub _unpackObjects {
    my ($data, $options) = @_;
    if (reftype $data eq 'HASH') {
        return _unpackObjectsHash($data, $options);
    } elsif (reftype $data eq 'ARRAY') {
        return _unpackObjectsArray($data, $options);
    }
    return undef;
}

sub _unpackObjectsHash {
    my ($hash, $options) = @_;
    my $class = delete $hash->{$options->{magicString}};
    if ($class) {
        my $fromPackedMethodName = $options->{fromPackedMethodName};
        if ($class->can($fromPackedMethodName)) {
            return $class->$fromPackedMethodName($hash);
        }
        bless $hash, $class;
    }
    foreach my $key (keys %$hash) {
        my $newVal = _unpackObjects($hash->{$key}, $options);
        $hash->{$key} = $newVal
            if defined $newVal;
    }
    return undef;
}

sub _unpackObjectsArray {
    my ($array, $options) = @_;
    if (scalar @$array >= 2 && $array->[0] eq $options->{magicString}) {
        shift @$array;
        my $class = shift @$array;
        my $fromPackedMethodName = $options->{fromPackedMethodName};
        if ($class->can($fromPackedMethodName)) {
            return $class->$fromPackedMethodName($array);
        }
        bless $array, $class;
    }
    foreach my $i (0..$#$array) {
        my $newVal = _unpackObjects($array->[$i], $options);
        $array->[$i] = $newVal
            if defined $newVal;
    }
    return undef;
}

sub _setDefaultOptions {
    my ($options) = @_;
    $options->{toPackedMethodName} //= DEFAULT_TO_PACKED_METHOD_NAME;
    $options->{fromPackedMethodName} //= DEFAULT_FROM_PACKED_METHOD_NAME;
    if (! exists $options->{magicString}) {
        $options->{magicString} = DEFAULT_MAGIC_STRING;
    }
}

=head1 NAME

Class::Storage - pack objects by removing blessing so they can be unpacked back
into objects again later.

Handles blessed HASHes and ARRAYs

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

This module came into existence out of the need to be able to send I<objects>
over JSON. JSON does not allow any blessed references to be sent by default and
if sent, provides no generic way to resurrect these objects again after
decoding. This can now all be done like this:

    use JSON;
    use Class::Storage qw(packObjects unpackObjects);

    my $object = bless { a => 1 }, 'MyModule';
    my $packed = packObjects( $object );

    # $packed is now { __class__ => 'MyModule', a => 1 }

    print $writeHandle encode_json($packed), "\n";

    # And on the other "side":

    my $jsonString = <$readHandle>;
    my $packed = decode_json($jsonString);
    my $unpackedObject = unpackObjects($packed);

    # $unpacked is now bless { a => 1 }, 'MyModule'
    # Which is_deeply the same as $object that we started with

However, there is no JSON-specific functionality in this module whatsoever,
only a way to cleanly remove the bless-ing in a way that reliably can be
re-introduced later.

=head1 DESCRIPTION

=head2 Using a magic string

As you can see from the L</"SYNOPSIS">, we use a magic string (C<__class__> by
default) to store the class information for HASHes and ARRAYs.

So C<packObjects> turns:

    bless { key => "value" }, "ModuleA";
    bless [ "val1", "val2" ], "ModuleB";

into:

    { __class__ => 'ModuleA', key => "value" }
    [ "__class__", 'ModuleB', "val1", "val2" ]

C<unpackObjects> converts any hashes with the magic string as a key and any
arrays with the magic string as the first element back to blessed references

This "magic string" can be given as an option (see L</"OPTIONS">), but if you
cannot live with a magic string, you can also provide
C<< magicString => undef >>. But then you won't be able to unpack that data and
turn it back into objects. If this is your itch, you may actually want
L<Data::Structure::Util> instead.

=head2 Returns packed/unpacked data + modifies input argument

The valid data is returned. However, for speed, we also modify and re-use data
from the input value. So don't rely on being able to reuse the C<$data> input
for C<packObjects> and C<unpackObjects> after they've been called and don't
modify them either.

If you don't want your input modified:

    use Storable qw(dclone);
    my $pristineData = somesub();
    my $packed = packObjects(dclone($pristineData));

=head2 Inspiration

Class::Storage is inspired by L<MooseX::Storage> but this is a generic
implementation that works on all plain perl classes that are implemented as
blessed references to HASHes and ARRAYs (B<only> hashes and arrays).

NOTE: L<MooseX::Storage> uses C<__CLASS__> as its magic string and we use
C<__class__> to make sure they're not the same.

=head2 C<TO_PACKED> and C<FROM_PACKED>

If you want to control how internal state gets represeted when packed, then
provide a C<TO_PACKED> instance method. It will be called like:

    my $packed = $object->TO_PACKED();

This C<$packed> data will be used by C<packObjects> instead of the guts of
C<$object>.

Similarly, during C<unpackObjects>, if a module has a C<FROM_PACKED> static
method it will be called like this:

    my $object = $module->FROM_PACKED($packed);

As you can see, C<TO_PACKED> and C<FROM_PACKED> go together as pairs.

You can also modify the names of these methods with the C<toPackedMethodName>
and C<fromPackedMethodName> options. See L</"OPTIONS>.

=head1 NOTE ABOUT KINDS OF BLESSED OBJECTS

L<perlobj> says:

"... it's possible to bless any type of data structure or referent, including
scalars, globs, and subroutines. You may see this sort of thing when looking at
code in the wild."

In particular I've seen several XS modules create instances where the internal
state is not visible to Perl, and hence cannot be handled properly by this
module. Here is an example with JSON:

    use Data::Dumper;
    use JSON;
    print Dumper(JSON->new()->pretty(1));
    # prints
    # $VAR1 = bless( do{\(my $o = '')}, 'JSON' );

Clearly a L<JSON> object has internal state and other data. This is an example
of a blessed reference, but not a blessed HASH or ARRAY that Class::Storage can
handle. If you try C<packObjects>-ing such a JSON instance, Class::Storage will
just leave the JSON object altogether untouched.

=head1 EXPORT

    our @EXPORT_OK = qw(packObjects unpackObjects);

=head1 SUBROUTINES/METHODS

Both C<packObjects> and C<unpackObjects> share the same C<%options>. See
L</"OPTIONS"> below.

=head2 packObjects

    my $packed = packObjects($blessed, %options);

=head2 unpackObjects

    my $unpacked = unpackObjects($unbessed, %options);

=head1 OPTIONS

These options are common to C<packObjects> and C<unpackObjects>:

=over 4

=item * C<toPackedMethodName>

This option lets you change the name of the C<TO_UNBLESSED> method to something
else. Hint: C<TO_JSON> could be a good idea here!

=item * C<fromPackedMethodName>

This option lets you change the name of the C<TO_BLESSED> method to something
else. Hint: C<FROM_JSON> could be a good idea here, even though L<JSON>
doesn't have such a method. Which is actually the entire Raison d'Etre of this
module!

=item * C<magicString>

Change the magic string used to store the class name to something else than
C<__class__>.

If this is false, don't store class information at all, in which case
C<packObjects> becomes analogous to L<Data::Structure::Util::packObjects>.

=back

=encoding UTF-8

=head1 AUTHOR

Peter Valdemar Mørch, C<< <peter@morch.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/pmorch/perl-Class-Storage/issues>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Storage

You can also look for information at:

=over 4

=item * Repository and Bug Tracker on Github

L<https://github.com/pmorch/perl-Class-Storage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Storage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Storage>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Storage/>

=back

=head1 ACKNOWLEDGEMENTS

This has been inspired by many sources, but checkout:

=over 4

=item * How to convert Perl objects into JSON and vice versa - Stack Overflow

L<http://stackoverflow.com/questions/4185482/how-to-convert-perl-objects-into-json-and-vice-versa/4185679>

=item * How do I turn Moose objects into JSON for use in Catalyst?

L<http://stackoverflow.com/questions/3391967/how-do-i-turn-moose-objects-into-json-for-use-in-catalyst>

=item * MooseX-Storage

L<https://metacpan.org/release/MooseX-Storage>

=item * Brian D Foy's quick hack

Where he defines a TO_JSON in UNIVERSAL so it applies to all objects. It makes
a deep copy, unblesses it, and returns the data structure.

L<http://stackoverflow.com/a/2330077/345716>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Peter Valdemar Mørch.

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

1; # End of Class::Storage
