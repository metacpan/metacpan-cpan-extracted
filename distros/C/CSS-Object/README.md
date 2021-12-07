SYNOPSIS
========

        use CSS::Object;

VERSION
=======

        v0.1.3

DESCRIPTION
===========

[CSS::Object](https://metacpan.org/pod/CSS::Object){.perl-module} is a
object oriented CSS parser and manipulation interface.

CONSTRUCTOR
===========

new
---

To instantiate a new
[CSS::Object](https://metacpan.org/pod/CSS::Object){.perl-module}
object, pass an hash reference of following parameters:

*debug*

:   This is an integer. The bigger it is and the more verbose is the
    output.

*format*

:   This is a
    [CSS::Object::Format](https://metacpan.org/pod/CSS::Object::Format){.perl-module}
    object or one of its child modules.

*parser*

:   This is a
    [CSS::Object::Parser](https://metacpan.org/pod/CSS::Object::Parser){.perl-module}
    object or one of its child modules.

EXCEPTION HANDLING
==================

Whenever an error has occurred,
[CSS::Object](https://metacpan.org/pod/CSS::Object){.perl-module} will
set a
[Module::Generic::Exception](https://metacpan.org/pod/Module::Generic::Exception){.perl-module}
object containing the detail of the error and return undef.

The error object can be retrieved with the inherited [\"error\" in
Module::Generic](https://metacpan.org/pod/Module::Generic#error){.perl-module}
method. For example:

        my $css = CSS::Object->new( debug => 3 ) || die( CSS::Object->error );

METHODS
=======

add\_element
------------

Provided with a
[CSS::Object::Element](https://metacpan.org/pod/CSS::Object::Element){.perl-module}
object and this adds it to the list of css elements.

It uses an array object [\"elements\"](#elements){.perl-module} which is
an
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
object.

add\_rule
---------

Provided with a
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
object and this adds it to our list of rules. It returns the rule object
that was added.

as\_string
----------

This will return the css data structure, currently registered, as a
string.

It takes an optional
[CSS::Object::Format](https://metacpan.org/pod/CSS::Object::Format){.perl-module}
object as a parameter, to control the output. If none are provided, it
will use the default one calling [\"format\"](#format){.perl-module}

builder
-------

This returns a new
[CSS::Object::Builder](https://metacpan.org/pod/CSS::Object::Builder){.perl-module}
object.

charset
-------

This sets or gets the css charset. It stores the value in a
[Module::Generic::Scalar](https://metacpan.org/pod/Module::Generic::Scalar){.perl-module}
object.

elements
--------

Sets or gets the array of CSS elements. This is a
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
object that accepts only
[CSS::Object::Element](https://metacpan.org/pod/CSS::Object::Element){.perl-module}
objects or its child classes, such as
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module},
[CSS::Object::Comment](https://metacpan.org/pod/CSS::Object::Comment){.perl-module},
etc

format
------

Sets or gets a
[CSS::Object::Format](https://metacpan.org/pod/CSS::Object::Format){.perl-module}
object. See [\"as\_string\"](#as_string){.perl-module} below for more
detail about their use.

[CSS::Object::Format](https://metacpan.org/pod/CSS::Object::Format){.perl-module}
objects control the stringification of the css structure. By default, it
will return the data in a string identical or at least very similar to
the one parsed if it was parsed.

get\_rule\_by\_selector
-----------------------

Provided with a selector and this returns a
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
object or an empty string.

Hoever, if this method is called in an object context, such as chaining,
then it returns a
[Module::Generic::Null](https://metacpan.org/pod/Module::Generic::Null){.perl-module}
object instead of an empty string to prevent the perl error of
`xxx method called on an undefined value`. For example:

        $css->get_rule_by_selector( '.does-not-exists' )->add_element( $elem ) ||
        die( "Unable to add css element to rule \".does-not-exists\": ", $css->error );

But, in a non-object context, such as:

        my $rule = $css->get_rule_by_selector( '.does-not-exists' ) ||
        die( "Unable to add css element to rule \".does-not-exists\": ", $css->error );

[\"get\_rule\_by\_selector\"](#get_rule_by_selector){.perl-module} will
return an empty value.

load\_parser
------------

This will instantiate a new object based on the parser name specified
with [\"parser\"](#parser){.perl-module} or during css object
instantiation.

It returns a new
[CSS::Object::Parser](https://metacpan.org/pod/CSS::Object::Parser){.perl-module}
object, or one of its child module matching the
[\"parser\"](#parser){.perl-module} specified.

new\_comment
------------

This returns a new
[CSS::Object::Comment](https://metacpan.org/pod/CSS::Object::Comment){.perl-module}
object and pass its instantiation method the provided arguments.

        return( $css->new_comment( $array_ref_of_comment_ilnes ) );

new\_property
-------------

This takes a property name, and an optional value o array of values and
return a new
[CSS::Object::Property](https://metacpan.org/pod/CSS::Object::Property){.perl-module}
object

new\_rule
---------

This returns a new
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
object.

new\_selector
-------------

This takes a selector name and returns a new
[CSS::Object::Selector](https://metacpan.org/pod/CSS::Object::Selector){.perl-module}
object.

new\_value
----------

This takes a property value and returns a new
[CSS::Object::Value](https://metacpan.org/pod/CSS::Object::Value){.perl-module}
object.

parse\_string
-------------

Provided with some css data and this will instantiate the
[\"parser\"](#parser){.perl-module}, call [\"parse\_string\" in
CSS::Object::Parser](https://metacpan.org/pod/CSS::Object::Parser#parse_string){.perl-module}
and returns an array of
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
objects. The array is an array object from
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
and can be used as a regular array or as an object.

parser
------

Sets or gets the
[CSS::Object::Parser](https://metacpan.org/pod/CSS::Object::Parser){.perl-module}
object to be used by [\"parse\_string\"](#parse_string){.perl-module} to
parse css data.

A valid parser object can be from
[CSS::Object::Parser](https://metacpan.org/pod/CSS::Object::Parser){.perl-module}
or any of its sub modules.

It returns the current parser object.

purge
-----

This empties the array containing all the
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
objects.

read\_file
----------

Provided with a css file, and this will load it into memory and parse it
using the parser name registered with
[\"parser\"](#parser){.perl-module}.

It can also take an array reference of css files who will be each fed to
[\"read\_file\"](#read_file){.perl-module}

It returns the
[CSS::Object](https://metacpan.org/pod/CSS::Object){.perl-module} used
to call this method.

read\_string
------------

Provided with some css data, and this will call
[\"parse\_string\"](#parse_string){.perl-module}. It also accepts an
array reference of data.

It returns the css object used to call this method.

rules
-----

This sets or gets the
[Module::Generic::Array](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
object used to store all the
[CSS::Object::Rule](https://metacpan.org/pod/CSS::Object::Rule){.perl-module}
objects.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55cf7803bcd0)"}\>

SEE ALSO
========

[CSS::Object](https://metacpan.org/pod/CSS::Object){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
