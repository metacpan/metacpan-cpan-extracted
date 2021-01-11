# NAME

Class::Data::TIN - DEPRECATED - Translucent, Inheritable, Nonpolluting class data

# VERSION

version 0.03

# SYNOPSIS

    use Class::Data::TIN qw(get_classdata set_classdata append_classdata);
    # or
    # use Class::Data::TIN qw(get set append);
    # but I prefer the first option, because of a less likly
    # namespace clashing

    # generate class data in your PACAKGE
    package My::Stuff;
    use Class::Data::TIN;

    our @ISA=(qw (Our::Stuff));

    my $tin=Class::Data::TIN->new(__PACKAGE__,
                        {
                         string=>"a string",
                         string2=>"another string",
                         array=>['foo','bar'],
                         hash=>{
                                foo=>'bar',
                                jaja=>'neinein',
                               },
                         code=>sub{return "bla"}
                        });


     print $tin->get_classdata('string');
     # or
     # print My::Stuff->get_classdata('string');
     # prints "a string"

     print $tin->get_classdata('newstring');
     # prints nothing, as newstring is not defined

     $tin->set_classdata('newstring','now I am here');
     print $self->get_classdata('newstring');
     # prints "now I am here"

     $tin->append_classdata('newstring',', or am I?');
     print $tin->get_classdata('newstring');
     # prints "now I am here, or am I?"

# DESCRIPTION

THIS MODULE IS DEPRECATED! I used it the last time ~20 years ago, and if I needed a similar functionality now, I would use Moose and/or some meta programming.

But here are the old docs, anyway:

Class::Data::TIN implements Translucent Inheritable Nonpolluting Class Data.

The thing I don't like with Class::Data::Inheritable or the implementations suggested in perltootc is that you end up with lots of accessor routines in your namespace.

Class::Data::TIN works around this "problem" by storing the Class Data in its own namespace (mirroring the namespace and @ISA hierarchies of the modules using it) and supplying the using packages with (at this time) three meta-accessors called `get_classdata` (or just `get`), `set_classdata` (`set`) and `append_classdata` (`append`). It achieves this with some black magic (namespace munging & evaling).

## new ($package,$datastruct)

new takes the package name of the package needing ClassData, and a data structrure passed as a hashref, a hash or a path to a file returning a hashref if called with `do`. It then installs a new package by appending "Class::Data::TIN::" to `$package`, copying `$package`s @ISA to the new package and saving `$data` in the var `$_tin`

Then for every key in `$data` accessor methods are generated in the new namespace.

new() returns the name of the original package as a string (**not** as a blessed reference!), so that the calling package may use the return value to modifiy the Class Data. This is done because I have to discern between **object** invocation and **class** invocation of the Class Data manipulating methods. Ideally, if an object modifies the Class Data, this changes are only visible to this object. **NOTE:** But this is not implemented yet. You can only modify Class Data when calling directly with ClassName->set, or with the return value of new() (which is, for example, nothing but the string "ClassName").

**Example:**

    package My::Stuff;
    use Class::Data::TIN;
    our @ISA=('Other::Stuff');
    my $tin=Class::Data::TIN->new(__PACKAGE__,
                        {
                         string=>"a string",
                        });

In new(), the following code is eval'ed:

    package Class::Data::TIN::My::Stuff;
    our @ISA=(qw (Class::Data::TIN::Other::Stuff));
    our $_tin;
    $_tin=$data;

and accesors are generated, that look sort of like this:

    sub string {
        my $self=shift;
        $_tin->{'string'} = shift if @_;
        return $_tin->{'string'};
     }

The point is that `string` and all other accessors are generate in a Namespace in Class::Data::TIN::My::Stuff, and **not** in My::Stuff, thus keeping My::Stuff neat and tidy.

look at the test script (test.pl) for a more complex example.

## get\_classdata ($key)

returns the value of the given key.

## set\_classdata ($key,$val)

set the key to the given value.

Translucency is implemented here by making a new accessor in the pseudo-class. (copy on write)

## append\_classdata ($key,$value \[,$value2,..\])

appends some values to a key. sets a new key if the key wasn't there. Does copy on write. You can also use append to override the value of a HASH in a parent class (simply append the value you'd like to override to the HASH)

## \_make\_accessor

internal method, don't call it!

\_make\_accessor checks if there allready exists an accessor for the given key. If not, it dumps one into the appropriate symbol table.

## TODO

A Lot:

- implement object translucency
- test different kinds to call new
- let user decide wheter object is allowed to modify class data

## EXPORT

None by default.

get get\_classdata set set\_classdata append append\_classdata, if you ask for it

# SEE ALSO

perltootc, Class::Data::Inheritable

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2001 - 2002 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 137:

    &#x3d;back doesn't take any parameters, but you said =back 4
