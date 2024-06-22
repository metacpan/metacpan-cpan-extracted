[![Kwalitee](https://cpants.cpanauthors.org/dist/Class-Simple-Cached.png)](http://cpants.cpanauthors.org/dist/Class-Simple-Cached)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Cache+messages+to+an+object+#perl&url=https://github.com/nigelhorne/class-simple-cached&via=nigelhorne)

# NAME

Class::Simple::Cached - cache messages to an object

# VERSION

Version 0.05

# SYNOPSIS

A sub-class of [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

You can use this class to create a caching layer to an object of any class
that works on objects with a get/set model such as:

    use Class::Simple;
    my $obj = Class::Simple->new();
    $obj->val('foo');
    my $oldval = $obj->val();

# SUBROUTINES/METHODS

## new

Creates a Class::Simple::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands clear(), get() and set() calls,
such as an [CHI](https://metacpan.org/pod/CHI) object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) is instantiated
and that is used.

## can

Returns if the embedded object can handle a message

## isa

Returns if the embedded object is the given type of object

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Doesn't work with [Memoize](https://metacpan.org/pod/Memoize).

Only works on messages that take no arguments.
For that, use [Class::Simple::Readonly::Cached](https://metacpan.org/pod/Class%3A%3ASimple%3A%3AReadonly%3A%3ACached).

Please report any bugs or feature requests to [https://github.com/nigelhorne/Class-Simple-Readonly/issues](https://github.com/nigelhorne/Class-Simple-Readonly/issues).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple), [CHI](https://metacpan.org/pod/CHI)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Cached

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Class-Simple-Cached](https://metacpan.org/release/Class-Simple-Cached)

- Source Repository

    [https://github.com/nigelhorne/Class-Simple-Readonly-Cached](https://github.com/nigelhorne/Class-Simple-Readonly-Cached)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Class-Simple-Cached](http://cpants.cpanauthors.org/dist/Class-Simple-Cached)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Class-Simple-Cached](http://matrix.cpantesters.org/?dist=Class-Simple-Cached)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Class::Simple::Cached](http://deps.cpantesters.org/?module=Class::Simple::Cached)

# LICENCE AND COPYRIGHT

Author Nigel Horne: `njh@bandsman.co.uk`
Copyright (C) 2019-2024, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
