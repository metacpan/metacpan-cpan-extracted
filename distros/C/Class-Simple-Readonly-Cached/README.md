# NAME

Class::Simple::Readonly::Cached - cache messages to an object

# VERSION

Version 0.05

# SYNOPSIS

A sub-class of [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

Note that it only works on objects which doesn't change its state based on input

    $val = $obj->val();
    $val = $obj->val(a => 'b');

# SUBROUTINES/METHODS

## new

Creates a Class::Simple::Readonly::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands get() and set() calls,
such as an [CHI](https://metacpan.org/pod/CHI) object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) is instantiated
and that is used.

## object

Return the encapsulated object

## state

Returns the state of the object

    print Data::Dumper->new([$obj->state()]->Dump();

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Doesn't work with [Memoize](https://metacpan.org/pod/Memoize).

Please report any bugs or feature requests to `bug-class-simple-readonly-cached at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Simple-Readonly-Cached](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Simple-Readonly-Cached).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

[Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple), [CHI](https://metacpan.org/pod/CHI)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Readonly::Cached

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Simple-Readonly-Cached](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Simple-Readonly-Cached)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Class-Simple-Readonly-Cached](http://cpanratings.perl.org/d/Class-Simple-Readonly-Cached)

- Search CPAN

    [http://search.cpan.org/dist/Class-Simple-Readonly-Cached/](http://search.cpan.org/dist/Class-Simple-Readonly-Cached/)

# LICENSE AND COPYRIGHT

Author Nigel Horne: `njh@bandsman.co.uk`
Copyright (C) 2019, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
