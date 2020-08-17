# NAME

CSS::Object - CSS Object Oriented

# SYNOPSIS

    use CSS::Object;

# VERSION

    v0.1.1

# DESCRIPTION

[CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) is a object oriented CSS parser and manipulation interface.

# CONSTRUCTOR

## new

To instantiate a new [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) object, pass an hash reference of following parameters:

- _debug_

    This is an integer. The bigger it is and the more verbose is the output.

- _format_

    This is a [CSS::Object::Format](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AFormat) object or one of its child modules.

- _parser_

    This is a [CSS::Object::Parser](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AParser) object or one of its child modules.

# EXCEPTION HANDLING

Whenever an error has occurred, [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) will set a [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object containing the detail of the error and return undef.

The error object can be retrieved with the inherited ["error" in Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric#error) method. For example:

    my $css = CSS::Object->new( debug => 3 ) || die( CSS::Object->error );

# METHODS

## add\_element

Provided with a [CSS::Object::Element](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AElement) object and this adds it to the list of css elements.

It uses an array object ["elements"](#elements) which is an [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) object.

## add\_rule

Provided with a [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) object and this adds it to our list of rules. It returns the rule object that was added.

## as\_string

This will return the css data structure, currently registered, as a string.

It takes an optional [CSS::Object::Format](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AFormat) object as a parameter, to control the output. If none are provided, it will use the default one calling ["format"](#format)

## builder

This returns a new [CSS::Object::Builder](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ABuilder) object.

## charset

This sets or gets the css charset. It stores the value in a [Module::Generic::Scalar](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AScalar) object.

## elements

Sets or gets the array of CSS elements. This is a [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) object that accepts only [CSS::Object::Element](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AElement) objects or its child classes, such as [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule), [CSS::Object::Comment](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AComment), etc

## format

Sets or gets a [CSS::Object::Format](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AFormat) object. See ["as\_string"](#as_string) below for more detail about their use.

[CSS::Object::Format](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AFormat) objects control the stringification of the css structure. By default, it will return the data in a string identical or at least very similar to the one parsed if it was parsed.

## get\_rule\_by\_selector

Provided with a selector and this returns a [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) object or an empty string.

## load\_parser

This will instantiate a new object based on the parser name specified with ["parser"](#parser) or during css object instantiation.

It returns a new [CSS::Object::Parser](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AParser) object, or one of its child module matching the ["parser"](#parser) specified.

## new\_comment

This returns a new [CSS::Object::Comment](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AComment) object and pass its instantiation method the provided arguments.

    return( $css->new_comment( $array_ref_of_comment_ilnes ) );

## new\_property

This takes a property name, and an optional value o array of values and return a new [CSS::Object::Property](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AProperty) object

## new\_rule

This returns a new [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) object.

## new\_selector

This takes a selector name and returns a new [CSS::Object::Selector](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ASelector) object.

## new\_value

This takes a property value and returns a new [CSS::Object::Value](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AValue) object.

## parse\_string

Provided with some css data and this will instantiate the ["parser"](#parser), call ["parse\_string" in CSS::Object::Parser](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AParser#parse_string) and returns an array of [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) objects. The array is an array object from [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) and can be used as a regular array or as an object.

## parser

Sets or gets the [CSS::Object::Parser](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AParser) object to be used by ["parse\_string"](#parse_string) to parse css data.

A valid parser object can be from [CSS::Object::Parser](https://metacpan.org/pod/CSS%3A%3AObject%3A%3AParser) or any of its sub modules.

It returns the current parser object.

## purge

This empties the array containing all the [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) objects.

## read\_file

Provided with a css file, and this will load it into memory and parse it using the parser name registered with ["parser"](#parser).

It can also take an array reference of css files who will be each fed to ["read\_file"](#read_file)

It returns the [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) used to call this method.

## read\_string

Provided with some css data, and this will call ["parse\_string"](#parse_string). It also accepts an array reference of data.

It returns the css object used to call this method.

## rules

This sets or gets the [Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) object used to store all the [CSS::Object::Rule](https://metacpan.org/pod/CSS%3A%3AObject%3A%3ARule) objects.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject)

# COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
