SYMOPSIS
========

        use Changes;
        my $c = Changes->load( '/some/where/Changes',
        {
        file => '/some/where/else/CHANGES',
        max_width => 78,
        type => 'cpan',
        debug => 4,
        }) || die( Changes->error );
        say "Found ", $c->releases->length, " releases.";
        my $rel = $c->add_release(
            version => 'v0.1.1',
            # Accepts relative time
            datetime => '+1D',
            note => 'CPAN update',
        ) || die( $c->error );
        $rel->changes->push( $c->new_change(
            text => 'Minor corrections in unit tests',
        ) ) || die( $rel->error );
        # or
        my $change = $rel->add_change( text => 'Minor corrections in unit tests' );
        $rel->delete_change( $change );
        my $array_object = $c->delete_release( $rel ) ||
            die( $c->error );
        say sprintf( "%d releases removed.", $array_object->length );
        # or $c->remove_release( $rel );
        # Writing to /some/where/else/CHANGES even though we read from /some/where/Changes
        $c->write || die( $c->error );

VERSION
=======

        v0.2.2

DESCRIPTION
===========

This module is designed to read and update `Changes` files that are
provided as part of change management in software distribution.

It is not limited to CPAN, and is versatile and flexible giving you a
lot of control.

Its distinctive value compared to other modules that handle `Changes`
file is that it does not attempt to reformat release and change
information if they have not been modified. This ensure not just speed,
but also that existing formatting of `Changes` file remain unchanged.
You can force reformatting of any release section by calling [\"reset\"
in
Changes::Release](https://metacpan.org/pod/Changes::Release#reset){.perl-module}

This module does not [\"die\" in
perlfunc](https://metacpan.org/pod/perlfunc#die){.perl-module} upon
error, but instead returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module},
so you need to check for the return value when you call any methods in
this package distribution.

CONSTRUCTOR
===========

new
---

Provided with an optional hash or hash reference of properties-values
pairs, and this will instantiate a new
[Changes](https://metacpan.org/pod/Changes){.perl-module} object and
return it.

Supported properties are the same as the methods listed below.

If an error occurs, this will return an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

load
----

Provided with a file path, and an optional hash or hash reference of
parameters, and this will parse the `Changes` file and return a new
object. Thus, this method can be called either using an existing object,
or as a class function:

        my $c2 = $c->load( '/some/where/Changes' ) ||
            die( $c->error );
        # or
        my $c = Changes->load( '/some/where/Changes' ) ||
            die( Changes->error );

load\_data
----------

Provided with some string and an optional hash or hash reference of
parameters and this will parse the `Changes` file data and return a new
object. Thus, this method can be called either using an existing object,
or as a class function:

        my $c2 = $c->load_data( $changes_data ) ||
            die( $c->error );
        # or
        my $c = Change->load_data( $changes_data ) ||
            die( Changes->error );

METHODS
=======

add\_epilogue
-------------

Provided with a text and this will set it as the Changes file epilogue,
i.e. an optional text that will appear at the end of the Changes file.

If the last element is not a blank line to separate the epilogue from
the last release information, then it will be added as necessary.

It returns the current object upon success, or an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

add\_preamble
-------------

Provided with a text and this will set it as the Changes file preamble.

If the text does not have 2 blank new lines at the end, those will be
added in order to separate the preamble from the first release line.

It returns the current object upon success, or an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

add\_release
------------

This takes either an
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
or an hash or hash reference of options required to create one (for that
refer to the
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
class), and returns the newly added release object.

The new release object will be added on top of the elements stack with a
blank new line separating it from the other releases.

If the same object is found, or an object with the same version number
is found, an error is returned, otherwise it returns the release object
thus added.

as\_string
----------

Returns a [string
object](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}
representing the entire `Changes` file. It does so by getting the value
set with [preamble](https://metacpan.org/pod/preamble){.perl-module},
and by calling `as_string` on each element stored in
[\"elements\"](#elements){.perl-module}. Those elements can be
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
and
[Changes::Group](https://metacpan.org/pod/Changes::Group){.perl-module}
and possibly
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}
object.

If an error occurred, it returns an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

The result of this method is cached so that the second time it is
called, the cache is used unless there has been any change.

defaults
--------

Sets or gets an hash of default values for the
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
or
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}
object when it is instantiated upon parsing with
[\"parse\"](#parse){.perl-module} or by the `new_release` or
`new_change` method found in
[Changes](https://metacpan.org/pod/Changes){.perl-module},
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
and
[Changes::Group](https://metacpan.org/pod/Changes::Group){.perl-module}

Default is `undef`, which means no default value is set.

        my $ch = Changes->new(
            file => '/some/where/Changes',
            defaults => {
                # for Changes::Release
                datetime_formatter => sub
                {
                    my $dt = shift( @_ ) || DateTime->now;
                    require DateTime::Format::Strptime;
                    my $fmt = DateTime::Format::Strptime->new(
                        pattern => '%FT%T%z',
                        locale => 'en_GB',
                    );
                    $dt->set_formatter( $fmt );
                    $dt->set_time_zone( 'Asia/Tokyo' );
                    return( $dt );
                },
                # No need to provide it if it is just a space though, because it will default to it anyway
                spacer => ' ',
                # Not necessary if the custom datetime formatter has already set it
                time_zone => 'Asia/Tokyo',
                # for Changes::Change
                spacer1 => "\t",
                spacer2 => ' ',
                marker => '-',
                max_width => 72,
                wrapper => $code_reference,
                # for Changes::Group
                group_spacer => "\t",
                group_type => 'bracket', # [Some group]
            }
        );

delete\_release
---------------

This takes a list of release to remove and returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of those releases thus removed.

A release provided can either be a
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
object, or a version string.

When removing a release object, it will also take care of removing
following blank new lines that typically separate a release from the
rest.

If an error occurred, this will return an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

elements
--------

Sets or gets an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of all the elements within the `Changes` file. Those elements can be
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module},
[Changes::Group](https://metacpan.org/pod/Changes::Group){.perl-module},
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}
and `Changes::NewLine` objects.

epilogue
--------

Sets or gets the text of the epilogue. An epilogue is a chunk of text,
possibly multi line, that appears at the bottom of the Changes file
after the last release information, separated by a blank line.

file
----

        my $file = $c->file;
        $c->file( '/some/where/Changes' );

Sets or gets the file path of the Changes file. This returns a [file
object](https://metacpan.org/pod/Module::Generic::File){.perl-module}

```{=pod::coverage}
freeze
```
history
-------

This is an alias for [\"releases\"](#releases){.perl-module} and returns
an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
objects.

max\_width
----------

Sets or gets the maximum line width for a change inside a release. The
line width includes an spaces at the beginning of the line and not just
the text of the change itself.

For example:

        v0.1.0 2022-11-17T08:12:42+0900
            - Some very long line of change going here, which can be wrapped here at 78 characters

wrapped at 78 characters would become:

        v0.1.0 2022-11-17T08:12:42+0900
            - Some very long line of change going here, which can be wrapped here at 
              78 characters

new\_change
-----------

Returns a new
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}
object, passing it any parameters provided.

If an error occurred, it returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module}

new\_group
----------

Returns a new
[Changes::Group](https://metacpan.org/pod/Changes::Group){.perl-module}
object, passing it any parameters provided.

If an error occurred, it returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module}

new\_line
---------

Returns a new `Changes::NewLine` object, passing it any parameters
provided.

If an error occurred, it returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module}

new\_release
------------

Returns a new
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
object, passing it any parameters provided.

If an error occurred, it returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module}

new\_version
------------

Returns a new `Changes::Version` object, passing it any parameters
provided.

If an error occurred, it returns an [error
object](https://metacpan.org/pod/Module::Generic#error){.perl-module}

nl
--

Sets or gets the new line character, which defaults to `\n`

It returns a [number
object](https://metacpan.org/pod/Module::Generic::Number){.perl-module}

parse
-----

Provided with an array reference of lines to parse and this will parse
each line and create all necessary
[release](https://metacpan.org/pod/Changes::Release){.perl-module},
[group](https://metacpan.org/pod/Changes::Group){.perl-module} and
[change](https://metacpan.org/pod/Changes::Change){.perl-module}
objects.

It returns the current object it was called with upon success, and
returns an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

preamble
--------

Sets or gets the text of the preamble. A preamble is a chunk of text,
possibly multi line, that appears at the top of the Changes file before
any release information.

releases
--------

Read only. This returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
containing all the [release
objects](https://metacpan.org/pod/Changes::Release){.perl-module} within
the Changes file.

remove\_release
---------------

This is an alias for
[\"delete\_release\"](#delete_release){.perl-module}

serialise
---------

This is an alias for [\"as\_string\"](#as_string){.perl-module}

serialize
---------

This is an alias for [\"as\_string\"](#as_string){.perl-module}

time\_zone
----------

Sets or gets a time zone to use for the release date. A valid time zone
can either be an olson time zone string such as `Asia/Tokyo`, or an
[DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone){.perl-module}
object.

If set, it will be passed to all new
[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module}
object upon parsing with [\"parse\"](#parse){.perl-module}

It returns a
[DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone){.perl-module}
object upon success, or an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module} if
an error occurred.

type
----

Sets or get the type of `Changes` file format this is.

wrapper
-------

Sets or gets a code reference as a callback mechanism to return a
properly wrapped change text. This allows flexibility beyond the default
use of [Text::Wrap](https://metacpan.org/pod/Text::Wrap){.perl-module}
and [Text::Format](https://metacpan.org/pod/Text::Format){.perl-module}
by
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}.

If set, this is passed by [\"parse\"](#parse){.perl-module} when
creating
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module}
objects.

See [\"as\_string\" in
Changes::Change](https://metacpan.org/pod/Changes::Change#as_string){.perl-module}
for more information.

write
-----

This will open the file set with [\"file\"](#file){.perl-module} in
write clobbering mode and print out the result from
[\"as\_string\"](#as_string){.perl-module}.

It returns the current object upon success, and an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module} if
an error occurred.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55563a562938)"}\>

SEE ALSO
========

[Changes::Release](https://metacpan.org/pod/Changes::Release){.perl-module},
[Changes::Group](https://metacpan.org/pod/Changes::Group){.perl-module},
[Changes::Change](https://metacpan.org/pod/Changes::Change){.perl-module},
[Changes::Version](https://metacpan.org/pod/Changes::Version){.perl-module},
[Changes::NewLine](https://metacpan.org/pod/Changes::NewLine){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
