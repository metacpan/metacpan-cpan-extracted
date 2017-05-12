# NAME

Attribute::Contract - Design by contract via Perl attributes

# SYNOPSIS

    package Interface;
    use Attribute::Contract -types => [qw/Str slurpy ArrayRef/];

    sub do_smth :ContractRequires(Str, slurpy ArrayRef[Str]) :ContractEnsures(Str) {
        my $self = shift;
        my ($input_string, $array_ref_of_strings) = @_;

        return '...';
    }

    package Implementation;
    use base 'Interface';
    use Attribute::Contract;

    sub do_smth {
        my $self = shift;
        my ($input_string, $array_ref_of_strings) = @_;

        return 'ok';
    }

    Implementation->do_smth('hi', 'there'); # works

    Implementation->do_smth();              # croaks!
    Implementation->do_smth(sub {});        # croaks!

# DESCRIPTION

[Attribute::Contract](http://search.cpan.org/perldoc?Attribute::Contract) by using Perl attributes allows you to specify contract
([Design by Contract](http://en.wikipedia.org/wiki/Design\_by\_contract)) for
every method in your class. You can check incoming and outgoing values by
specifying `ContractRequires` and `ContractEnsures` attributes.

It's the most useful for interfaces or abstract classes when you want to control
whether your implementation follows the same interface and respects the Liskov
substitution principle.

This module uses [Type::Tiny](http://search.cpan.org/perldoc?Type::Tiny) underneath so all the checks is done via that
module. Check it out for more documention on type validation.

Why attributes? They feel and look natural and are applied during compile time.

## IMPORTING

When using [Attribute::Contract](http://search.cpan.org/perldoc?Attribute::Contract) one may want to import various types in order
to check them in attributes. Types themselves are not imported into the current
module but rather used when compiling attributes.

### Types

    package MyClass;
    use Attribute::Contract -types => [qw/ClassName Str/];

    sub static_method : ContractRequires(ClassName, Str) {
    };

    ...

    MyClass->static_method('string');

### Type libraries

When types are complex or the description is too long attributes might get not
very readable. In this case one can use type libraries (implemented again via
[Type::Tiny](http://search.cpan.org/perldoc?Type::Tiny)):

    package MyTypes;
    use Type::Library -base, -declare => qw(MyInt);
    use Type::Utils;
    use Types::Standard qw(Int);

    declare MyInt, as Int, where => {$_ > 0};

    package MyClass;
    use Attribute::Contract -library => 'MyTypes';

    sub static_method : ContractRequires(ClassName, MyInt) {
    }

    ...

    MyClass->static_method(5);

### Aliasing

If you don't like `ContractRequires` and `ContractEnsures` you can set your
own names:

    use Attribute::Contract -names => {requires => 'In', ensures => 'Out'}

    sub method : In(ClassName, Str) Out(Str) {
    }

## IMPLEMENTATION

### Inheritance

By default all the contracts are inherited. Just don't forget to `use`
[Attribute::Contract](http://search.cpan.org/perldoc?Attribute::Contract) in the derived class. But if no methods are overriden
then even `using` this module is not needed.

### Caching

During the compile time for every contract a Perl subroutine is built and
evaled. If the methods share the same contract they use the same checking code
reference. This speeds up the checking and saves some memory.

### Error reporting

Errors are as specific as possible. On error you will get a meaningful message
and a stack trace.

## SWITCHING OFF

You can switch off contract checking by specifying an environment variable
`NO_ATTRIBUTE_CONTRACT`.

# DEVELOPMENT

## Repository

    http://github.com/vti/attribute-contract

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
