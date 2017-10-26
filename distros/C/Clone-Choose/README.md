# NAME

Clone::Choose - Choose appropriate clone utility

# SYNOPSIS

    use Clone::Choose;

    my $data = {
        value => 42,
        href  => {
            set   => [ 'foo', 'bar' ],
            value => 'baz',
        },
    };

    my $cloned_data = clone $data;

    # it's also possible to use Clone::Choose and pass a clone preference
    use Clone::Choose qw(:Storable);

# DESCRIPTION

`Clone::Choose` checks several different modules which provides a
`clone()` function and selects an appropriate one. The default preference
is

    Clone
    Storable
    Clone::PP

This list might evolve in future. Please see ["EXPORTS"](#exports) how to pick a
particular one.

# EXPORTS

`Clone::Choose` exports `clone()` by default.

One can explicitly import `clone` by using

    use Clone::Choose qw(clone);

or pick a particular `clone` implementation

    use Clone::Choose qw(:Storable clone);

The exported implementation is resolved dynamically, which means that any
using module can either rely on the default backend preference or choose
a particular one.

It is also possible to select a particular `clone` backend by setting the
environment variable CLONE\_CHOOSE\_PREFERRED\_BACKEND to your preferred backend.

This also means, an already chosen import can't be modified like

    use Clone::Choose qw(clone :Storable);

When one seriously needs different clone implementations, our _recommended_
way to use them would be:

    use Clone::Choose (); # do not import
    my ($xs_clone, $st_clone);
    { local @Clone::Choose::BACKENDS = (Clone => "clone"); $xs_clone = Clone::Choose->can("clone"); }
    { local @Clone::Choose::BACKENDS = (Storable => "dclone"); $st_clone = Clone::Choose->can("clone"); }

Don't misinterpret _recommended_ - modifying `@Clone::Choose::BACKENDS`
has a lot of pitfalls and is unreliable beside such small examples. Do
not hesitate open a request with an appropriate proposal for choosing
implementations dynamically.

The use of `@Clone::Choose::BACKENDS` is discouraged and will be deprecated
as soon as anyone provides a better idea.

# PACKAGE METHODS

## backend

`backend` tells the caller about the dynamic chosen backend:

    use Clone::Choose;
    say Clone::Choose->backend; # Clone

This method currently exists for debug purposes only.

## get\_backends

`get_backends` returns a list of the currently supported backends.

# AUTHOR

    Jens Rehsack <rehsack at cpan dot org>
    Stefan Hermes <hermes at cpan dot org>

# BUGS

Please report any bugs or feature requests to
`bug-Clone-Choose at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clone-Choose](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clone-Choose).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Clone::Choose

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Clone-Choose](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Clone-Choose)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Clone-Choose](http://annocpan.org/dist/Clone-Choose)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Clone-Choose](http://cpanratings.perl.org/d/Clone-Choose)

- Search CPAN

    [http://search.cpan.org/dist/Clone-Choose/](http://search.cpan.org/dist/Clone-Choose/)

# LICENSE AND COPYRIGHT

    Copyright 2017 Jens Rehsack
    Copyright 2017 Stefan Hermes

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

# SEE ALSO

[Clone](https://metacpan.org/pod/Clone), [Clone::PP](https://metacpan.org/pod/Clone::PP), [Storable](https://metacpan.org/pod/Storable)
