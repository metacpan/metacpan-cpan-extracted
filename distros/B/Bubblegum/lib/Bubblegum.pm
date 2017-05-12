# ABSTRACT: Opinionated Modern Perl Development Framework
package Bubblegum;

use 5.10.0;
use namespace::autoclean;

use Moo 'with';

with 'Bubblegum::Role::Configuration';

our $VERSION = '0.45'; # VERSION

sub import {
    my $target = caller;
    my $class  = shift;

    $class->prerequisites($target);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum - Opinionated Modern Perl Development Framework

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    package Person;

    use Bubblegum::Class;

    has 'firstname' => (
        is       => 'ro',
        required => 1
    );

    sub greet {
        my $self = shift;
        my $subject = shift;

        # fatal assertions
        $self->asa_object;
        $subject->asa_string;

        $subject = $subject->titlecase;
        my $target = $self->firstname->titlecase;
        my $greeting = "Hello %s. My name is %s, nice to meet you.";

        return $subject->format($greeting, $target);
    }

And elsewhere:

    my $jeff = Person->new(firstname => 'jeffrey');
    $jeff->greet('amanda')->say;

=head1 DESCRIPTION

Bubblegum is a modern Perl development framework, it enforces common best
practices and is intended to be used to enhance your Perl environment and
development experience. The design goal of Bubblegum is to be as minimal as
possible, enabling as many core features as is justifiable, making the common
most repetitive programming tasks simply a method call away, and having all this
available by simply requiring this library. This framework is very opinionated
and designed around convention over configuration. Designed for adoption, all of
the techniques used in this framework are well-known by experienced Perl
developers and made conveniently available to programmers at all levels, i.e.,
no experimental features used. B<Note: This is an early release available for
testing and feedback and as such is subject to change.>

    use Bubblegum;
    # or Bubblegum::Class;
    # or Bubblegum::Prototype
    # or Bubblegum::Role
    # or Bubblegum::Singleton;

is equivalent to

    use 5.10.0;
    use strict;
    use warnings;
    use autobox;
    use autodie ':all';
    use feature ':5.10';
    use English -no_match_vars;
    use utf8::all;
    use mro 'c3';

with the exception that Bubblegum implements it's own autoboxing architecture.
The Bubblegum autobox classes are the foundation for this development framework.
The decision to re-implement many core and autobox functions was based on the
desire to build-in data validation and design a system using roles for a higher
level of abstraction. The following functionality is made available simply by
using Bubblegum:

    # integers

        my $range = 5->to(1);                   # [ 5, 4, 3, 2, 1 ]

    # floats

        my $strip = 3.1415927->incr->int;       # 4

    # strings

        my $greet = 'hello world'->titlecase;   # "Hello World"

    # arrays

        my $alpha = ['a'..'z'];
        my $map   = $alpha->keyed(1..26);       # { 1=>'a', 2='b', ... }

    # hashes

        my $map = { 1=>'a', 2=>'b', 3=>'c' };
        $map->reset->set(1 => 'z');             # { 1=>'z', 2=undef, 3=>undef }

    # routines

        my $code = ['a'..'z']->iterator;
        my $char = $code->call;                 # a

    # comparison operations

        my $ten = "10";                         # string containing the 10
        $ten->eqtv(10)                          # false, type/value mismatch
        $ten->eq(10)                            # true, coercive comparison
        10->eq($ten)                            # true, same as above
        "10"->type                              # string
        (10)->type                              # integer
        10->typeof('array')                     # false
        10->typeof('code')                      # false
        10->typeof('hash')                      # false
        10->typeof('integer')                   # true
        10->typeof('nil')                       # false
        10->typeof('null')                      # false
        10->typeof('number')                    # true
        10->typeof('string')                    # false
        10->typeof('undef')                     # false

    # include Moo as your default object-system (optional)

        use Bubblegum::Class;                   # Bubblegum w/ Moo
        use Bubblegum::Prototype;               # Bubblegum w/ Moo (Prototype)
        use Bubblegum::Role;                    # Bubblegum w/ Moo (Role)
        use Bubblegum::Singleton;               # Bubblegum w/ Moo (Singleton)

=head1 INTRODUCTION

Bubblegum makes essential core features and common functionality readily
available via automation (autoloading, autoboxing, autodying, etc). It promotes
modern Perl best practices by automatically enabling a standard configuration
(utf8::all, strict, warnings, features, etc) and by extending core functionality
with Bubblegum::Wrapper extensions. Bubblegum is an opinionated object-oriented
development framework, the core is designed to leverage as much of the Perl
core, 5.10+, as possible and uses Moo to provide a minimalistic object system
(compatible with Moose). This framework is modeled using object-roles for a
higher-level of abstraction and consistency.

=head1 FEATURES

=over 4

=item *

Requires 5.10.0

=item *

Enforces Strict Syntax and Enables Warnings

=item *

Exception Handling for Type Operations

=item *

Extendable Component-Based Autoboxing

=item *

Encoding and Decoding Utilities

=item *

UTF-8 Encoding For All IO Operations

=item *

Modern Method Order Resolution

=item *

Modern Minimalistic Object System

=item *

Functional and Object-Oriented Type Checking

=item *

Extendable with Optional Features and Enhancements

=back

=head1 RATIONALE

The TIMTOWTDI (there is more than one way to do it) motto has been a gift and a
curse. The Perl language (and community) has been centered around this concept
for quite some time, in that the language "doesn't try to tell the programmer
how to program" which makes it easy to write concise and powerful statements but
which also makes it easy to write extremely messy and incoherent software (with
great power comes great responsibility). Another downside is that as the number
of decisions a programmer has to make increases, their productivity decreases.
Enforced consistency is a path many other programming languages and frameworks
have adopted to great effect, so Bubblegum is one approach towards that end in
Perl.

=head2 Bubblegum Extras

Additional features and enhancements can be enabled by using utility packages
such as L<Bubblegum::Constraints>, which exports type constraint and validation
functions. Bubblegum is a Perl development framework; having it's feature-set
compartmentalized in such a way as to allow the maximum amount of
interoperability. Bubblegum can be used along-side any of the many
object-systems.

    use Bubblegum::Class;
    use Bubblegum::Constraints -isas;

    sub BUILDARGS {
        my $class = shift;
        my $data  = isa_hashref $_[0] ? $_[0] : {@_};

        # do stuff
        # ...

        return $data;
    }

=head2 Bubblegum Topology

Bubblegum type classes are built as extensions to the autobox type classes. The
following is the custom autobox type, subtype and roles hierarchy. All native
data types inherit their functionality from the universal class, then whichever
autobox subtype class is appropriate and so on. Bubblegum overlays object-roles
on top of this design to enforce constraints and consistency. The following is
the current layout of the object roles and relationships. Note, this will likely
evolve.

    INSTANCE  -+
        [ROLE] VALUE
               |
    UNDEF     -+
        [ROLE] ITEM
               |
    UNIVERSAL -+
        [ROLE] DEFINED
               |
               +- SCALAR -+
               |     [ROLE] VALUE
               |          |
               |          +- NUMBER -+
               |          |     [ROLE] VALUE
               |          |          |
               |          |          +- INTEGER
               |          |          |     [ROLE] VALUE
               |          |          |
               |          |          +- FLOAT
               |          |                [ROLE] VALUE
               |          |
               |          +- STRING
               |                [ROLE] VALUE
               |
               +- ARRAY
               |     [ROLE] REF
               |     [ROLE] LIST
               |     [ROLE] INDEXED
               |
               +- HASH
               |     [ROLE] REF
               |     [ROLE] KEYED
               |
               +- CODE
                    [ROLE] VALUE

=head2 Bubblegum Operations

The following classes have methods which can be invoked by variables containing
data of a type corresponding with the type the class is designed to handle.

=head3 Array Operations

Array operations work on arrays and array references. Please see
L<Bubblegum::Object::Array> for more information on operations associated with
array references.

=head3 Code Operations

Code operations work on code references. Please see L<Bubblegum::Object::Code>
for more information on operations associated with code references.

=head3 Hash Operations

Hash operations work on hash and hash references. Please see
L<Bubblegum::Object::Hash> for more information on operations associated with
hash references.

=head3 Integer Operations

Integer operations work on integer and number data. Please see
L<Bubblegum::Object::Integer> for more information on operations associated with
integers.

=head3 Number Operations

Number operations work on data that meets the criteria for being a number.
Please see L<Bubblegum::Object::Number> for more information on operations
associated with numbers.

=head3 String Operations

String operations work on data that meets the criteria for being a string.
Please see L<Bubblegum::Object::String> for more information on operations
associated with strings.

=head3 Undef Operations

Undef operations work on variables whose value is undefined. Note, undef
operations do not work on undef directly. Please see L<Bubblegum::Object::Undef>
for more information on operations associated with undefined variables.

=head3 Universal Operations

Universal operations work on all data which meets the criteria for being
defined. Please see L<Bubblegum::Object::Universal> for more information on
operations associated with array references.

=head2 Bubblegum Wrappers

A Bubblegum::Wrapper module exists to extend Bubblegum itself and further extend
the functionality of native data types by letting the data bless itself into
wrappers (plugins) in a chain-able discoverable manner. It's also useful as a
technique for coercion and indirect object instantiation. The following is an
example:

    use Bubblegum;

    my $hash = {1..3,{4,{5,6,7,{8,9,10,11}}}};
    my $json = $hash->json; # load Bubblegum::Wrapper::Json dynamically
    say $json->encode;      # encode the hash as json

    # {"1":2,"3":{"4":{"7":{"8":9,"10":11},"5":6}}}

The follow list of wrappers are distributed with the Bubblegum distribution:

=head3 Digest Wrapper

The Bubblegum digest wrapper, L<Bubblegum::Wrapper::Digest>, provides access to
various hashing algorithms to encode/decode messages.

=head3 Dumper Wrapper

The Bubblegum data-dumper wrapper, L<Bubblegum::Wrapper::Dumper>, provides
functionality to encode/decode Perl data structures.

=head3 Encoder Wrapper

The Bubblegum encoding wrapper, L<Bubblegum::Wrapper::Encoder>, provides access
to content encoding/decoding functionality.

=head3 JSON Wrapper

The Bubblegum json wrapper, L<Bubblegum::Wrapper::Json>, provides functionality
to encode/decode Perl data structures as JSON documents.

=head3 YAML Wrapper

The Bubblegum yaml wrapper, L<Bubblegum::Wrapper::Yaml>, provides functionality
to encode/decode Perl data structures as YAML documents.

=head2 Extending Bubblegum

As an alternative to using Bubblegum wrappers, you can rebase (i.e. extend) the
Bubblegum framework directly, and customize it for your application-specific
usages. The following is an example of how you can accomplish this:

    package MyApp::Core;

    use parent 'Bubblegum';

    use Bubblegum::Namespace Array     => 'MyApp::Core::Object::Array';
    use Bubblegum::Namespace Code      => 'MyApp::Core::Object::Code';
    use Bubblegum::Namespace Float     => 'MyApp::Core::Object::Float';
    use Bubblegum::Namespace Hash      => 'MyApp::Core::Object::Hash';
    use Bubblegum::Namespace Integer   => 'MyApp::Core::Object::Integer';
    use Bubblegum::Namespace Number    => 'MyApp::Core::Object::Number';
    use Bubblegum::Namespace Scalar    => 'MyApp::Core::Object::Scalar';
    use Bubblegum::Namespace String    => 'MyApp::Core::Object::String';
    use Bubblegum::Namespace Undef     => 'MyApp::Core::Object::Undef';
    use Bubblegum::Namespace Universal => 'MyApp::Core::Object::Universal';

    1;

The example above creates an application-specific package derived from Bubblegum
and changes the default Bubblegum object class namespaces to application-specific
ones. Each class will need to be derived from its respective Bubblegum
counterpart, for example:

    package MyApp::Core::Object::Array;

    use parent 'Bubblegum::Object::Array';

    sub pushpop {
        push @{(shift)}, pop @{(shift)};
    }

    1;

This allows you to add and/or override object methods and tailor object type
handling around your specific use-cases.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 CONTRIBUTORS

=over 4

=item *

Toby Inkster <tobyink@cpan.org>

=item *

Сергей Романов <sromanov@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
