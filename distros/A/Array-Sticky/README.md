NAME
====
Array::Sticky - make elements of an array stick in place

SYNOPSIS
========
```perl
use Array::Sticky;

my @array;

tie @array, 'Array::Sticky', head => ['head'], body => [1..5];
# @array = ('head', 1..5)

unshift @array, 'shoulders';
# @array = ('head', 'shoulders', 1..5);

my $val = shift @array;
# $val = 'shoulders'
# @array = ('head', 1..5)
```

DESCRIPTION
===========
On very rare occasions, you want to make sure that the first few or last
few elements of an array remain in their relative positions - stuck to
the head of the array, or stuck to the tail. This module allows you to
accomplish that.

SEE ALSO
========
By itself this module is probably not all that interesting. See
Sticky::Array::INC for an actual case where you might care about using
this module.

BUGS
====
Please report bugs on this project's Github Issues page:
http://github.com/belden/perl-array-sticky/issues.

CONTRIBUTING
============
The repository for this software is freely available on this project's
Github page: http://github.com/belden/perl-array-sticky. You may fork it
there and submit pull requests in the standard fashion.

COPYRIGHT AND LICENSE
=====================

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it
under the same terms as Perl itself; either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

