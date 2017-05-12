# NAME

Class::Storage - pack objects by removing blessing so they can be unpacked back
into objects again later.

Handles blessed HASHes and ARRAYs

# VERSION

Version 0.02

# SYNOPSIS

This module came into existence out of the need to be able to send _objects_
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

# DESCRIPTION

## Using a magic string

As you can see from the ["SYNOPSIS"](#synopsis), we use a magic string (`__class__` by
default) to store the class information for HASHes and ARRAYs.

So `packObjects` turns:

    bless { key => "value" }, "ModuleA";
    bless [ "val1", "val2" ], "ModuleB";

into:

    { __class__ => 'ModuleA', key => "value" }
    [ "__class__", 'ModuleB', "val1", "val2" ]

`unpackObjects` converts any hashes with the magic string as a key and any
arrays with the magic string as the first element back to blessed references

This "magic string" can be given as an option (see ["OPTIONS"](#options)), but if you
cannot live with a magic string, you can also provide
`magicString => undef`. But then you won't be able to unpack that data and
turn it back into objects. If this is your itch, you may actually want
[Data::Structure::Util](https://metacpan.org/pod/Data::Structure::Util) instead.

## Returns packed/unpacked data + modifies input argument

The valid data is returned. However, for speed, we also modify and re-use data
from the input value. So don't rely on being able to reuse the `$data` input
for `packObjects` and `unpackObjects` after they've been called and don't
modify them either.

If you don't want your input modified:

    use Storable qw(dclone);
    my $pristineData = somesub();
    my $packed = packObjects(dclone($pristineData));

## Inspiration

Class::Storage is inspired by [MooseX::Storage](https://metacpan.org/pod/MooseX::Storage) but this is a generic
implementation that works on all plain perl classes that are implemented as
blessed references to HASHes and ARRAYs (**only** hashes and arrays).

NOTE: [MooseX::Storage](https://metacpan.org/pod/MooseX::Storage) uses `__CLASS__` as its magic string and we use
`__class__` to make sure they're not the same.

## `TO_PACKED` and `FROM_PACKED`

If you want to control how internal state gets represeted when packed, then
provide a `TO_PACKED` instance method. It will be called like:

    my $packed = $object->TO_PACKED();

This `$packed` data will be used by `packObjects` instead of the guts of
`$object`.

Similarly, during `unpackObjects`, if a module has a `FROM_PACKED` static
method it will be called like this:

    my $object = $module->FROM_PACKED($packed);

As you can see, `TO_PACKED` and `FROM_PACKED` go together as pairs.

You can also modify the names of these methods with the `toPackedMethodName`
and `fromPackedMethodName` options. See [""OPTIONS"](#options).

# NOTE ABOUT KINDS OF BLESSED OBJECTS

[perlobj](https://metacpan.org/pod/perlobj) says:

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

Clearly a [JSON](https://metacpan.org/pod/JSON) object has internal state and other data. This is an example
of a blessed reference, but not a blessed HASH or ARRAY that Class::Storage can
handle. If you try `packObjects`-ing such a JSON instance, Class::Storage will
just leave the JSON object altogether untouched.

# EXPORT

    our @EXPORT_OK = qw(packObjects unpackObjects);

# SUBROUTINES/METHODS

Both `packObjects` and `unpackObjects` share the same `%options`. See
["OPTIONS"](#options) below.

## packObjects

    my $packed = packObjects($blessed, %options);

## unpackObjects

    my $unpacked = unpackObjects($unbessed, %options);

# OPTIONS

These options are common to `packObjects` and `unpackObjects`:

- `toPackedMethodName`

    This option lets you change the name of the `TO_UNBLESSED` method to something
    else. Hint: `TO_JSON` could be a good idea here!

- `fromPackedMethodName`

    This option lets you change the name of the `TO_BLESSED` method to something
    else. Hint: `FROM_JSON` could be a good idea here, even though [JSON](https://metacpan.org/pod/JSON)
    doesn't have such a method. Which is actually the entire Raison d'Etre of this
    module!

- `magicString`

    Change the magic string used to store the class name to something else than
    `__class__`.

    If this is false, don't store class information at all, in which case
    `packObjects` becomes analogous to [Data::Structure::Util::packObjects](https://metacpan.org/pod/Data::Structure::Util::packObjects).

# AUTHOR

Peter Valdemar Mørch, `<peter@morch.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/pmorch/perl-Class-Storage/issues](https://github.com/pmorch/perl-Class-Storage/issues). I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Storage

You can also look for information at:

- Repository and Bug Tracker on Github

    [https://github.com/pmorch/perl-Class-Storage](https://github.com/pmorch/perl-Class-Storage)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Class-Storage](http://annocpan.org/dist/Class-Storage)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Class-Storage](http://cpanratings.perl.org/d/Class-Storage)

- Search CPAN

    [http://search.cpan.org/dist/Class-Storage/](http://search.cpan.org/dist/Class-Storage/)

# ACKNOWLEDGEMENTS

This has been inspired by many sources, but checkout:

- How to convert Perl objects into JSON and vice versa - Stack Overflow

    [http://stackoverflow.com/questions/4185482/how-to-convert-perl-objects-into-json-and-vice-versa/4185679](http://stackoverflow.com/questions/4185482/how-to-convert-perl-objects-into-json-and-vice-versa/4185679)

- How do I turn Moose objects into JSON for use in Catalyst?

    [http://stackoverflow.com/questions/3391967/how-do-i-turn-moose-objects-into-json-for-use-in-catalyst](http://stackoverflow.com/questions/3391967/how-do-i-turn-moose-objects-into-json-for-use-in-catalyst)

- MooseX-Storage

    [https://metacpan.org/release/MooseX-Storage](https://metacpan.org/release/MooseX-Storage)

- Brian D Foy's quick hack

    Where he defines a TO\_JSON in UNIVERSAL so it applies to all objects. It makes
    a deep copy, unblesses it, and returns the data structure.

    [http://stackoverflow.com/a/2330077/345716](http://stackoverflow.com/a/2330077/345716)

# LICENSE AND COPYRIGHT

Copyright 2015 Peter Valdemar Mørch.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
