# NAME

Class::Simple::Cached - cache messages to an object

# VERSION

Version 0.03

# SYNOPSIS

A sub-class of [Class::Simple](https://metacpan.org/pod/Class::Simple) which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

# SUBROUTINES/METHODS

## new

Creates a Class::Simple::Cached object.

It takes one mandatory parameter: cache,
which is an object which understands get() and set() calls,
such as an [CHI](https://metacpan.org/pod/CHI) object.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class [Class::Simple](https://metacpan.org/pod/Class::Simple) is instantiated
and that is used.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Doesn't work with [Memoize](https://metacpan.org/pod/Memoize).

Please report any bugs or feature requests to `bug-class-simple-cached at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Simple-Cached](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Simple-Cached).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

[Class::Simple](https://metacpan.org/pod/Class::Simple), [CHI](https://metacpan.org/pod/CHI)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Cached

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Simple-Cached](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Simple-Cached)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Class-Simple-Cached](http://cpanratings.perl.org/d/Class-Simple-Cached)

- Search CPAN

    [http://search.cpan.org/dist/Class-Simple-Cached/](http://search.cpan.org/dist/Class-Simple-Cached/)

# LICENSE AND COPYRIGHT

Author Nigel Horne: `njh@bandsman.co.uk`
Copyright (C) 2019, Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
