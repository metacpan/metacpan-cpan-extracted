# NAME

Array::Iterator - A simple class for iterating over Perl arrays

# VERSION

Version 0.135

# SYNOPSIS

`Array::Iterator` is a Perl module that provides a simple,
uni-directional iterator interface for traversing arrays.
It allows users to iterate over arrays, array references, or hash references containing an array, offering methods like next, has\_next, peek, and current to facilitate controlled access to elements.
The iterator maintains an internal pointer, ensuring elements are accessed sequentially without modifying the underlying array.
Tt offers a clean, object-oriented approach to iteration, inspired by Java’s Iterator interface.
The module is extendable, allowing subclassing for custom behaviour.

    use Array::Iterator;

    # create an iterator with an array
    my $i = Array::Iterator->new(1 .. 100);

    # create an iterator with an array reference
    my $i = Array::Iterator->new(\@array);

    # create an iterator with a hash reference
    my $i = Array::Iterator->new({ __array__ => \@array });

    # a base iterator example
    while ($i->has_next()) {
        if ($i->peek() < 50) {
            # ... do something because
            # the next element is over 50
        }
        my $current = $i->next();
        # ... do something with current
    }

    # shortcut style
    my @accumulation;
    push @accumulation => { item => $iterator->next() } while $iterator->has_next();

    # C++ ish style iterator
    for (my $i = Array::Iterator->new(@array); $i->has_next(); $i->next()) {
      my $current = $i->current();
      # .. do something with current
    }

    # common perl iterator idiom
    my $current;
    while ($current = $i->get_next()) {
      # ... do something with $current
    }

It is not recommended to alter the array during iteration, however
no attempt is made to enforce this (although I will if I can find an efficient
means of doing so). This class only intends to provide a clear and simple
means of generic iteration, nothing more (yet).

## new (@array | $array\_ref | $hash\_ref)

The constructor can be passed either a plain Perl array, an array reference,
or a hash reference (with the array specified as a single key of the hash,
\_\_array\_\_).
Single-element arrays are not supported by either of the first
two calling conventions, since it is not possible to distinguish between an
array of a single-element which happens to be an array reference and an
array reference of a single element, thus previous versions of the constructor
would raise an exception. If you expect to pass arrays to the constructor which
may have only a single element, then the array can be passed as the element
of a HASH reference, with the key, \_\_array\_\_:

    my $i = Array::Iterator->new({ __array__ => \@array });

## \_current\_index

An lvalue-ed subroutine that allows access to the iterator's internal pointer.
This can be used in a subclass to access the value.

## \_iteratee

This returns the item being iterated over, in our case an array.

## \_get\_item ($iteratee, $index)

This method is used by all other routines to access items. Given the iteratee
and an index, it will return the item being stored in the `$iteratee` at the index
of `$index`.

## iterated

Access to the \_iterated status, for subclasses

## has\_next(\[$n\])

This method returns a boolean. True (1) if there are still more elements in
the iterator, false (0) if there are not.

Takes an optional positive integer (> 0) that specifies the position you
want to check. This allows you to check if there an element at an arbitrary position.
Think of it as an ordinal number you want to check:

    $i->has_next(2);  # 2nd next element
    $i->has_next(10); # 10th next element

Note that `has_next(1)` is the same as `has_next()`.

Throws an exception if `$n` <= 0.

## hasNext

Alternative name for has\_next

## next

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, an exception
will be thrown.

## get\_next

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, it will return
undef.

This method was added to allow for a fairly common Perl iterator idiom of:

    my $current;
    while ($current = $i->get_next()) {
        ...
    }

In this,
the loop terminates once `$current` is assigned to a false value.
The only problem with this idiom for me is that it does not allow for
undefined or false values in the iterator. Of course, if this fits your
data, then there is no problem. Otherwise I would recommend the `has_next`/`next`
idiom instead.

## getNext

Alternative name for get\_next

## peek(\[$n\])

This method can be used to peek ahead at the next item in the iterator. It
is non-destructive, meaning it does not advance the internal pointer. If
this method is called and attempts to reach beyond the bounds of the iterator,
it will return undef.

Takes an optional positive integer (> 0) that specifies how far ahead you want to peek:

    $i->peek(2);  # gives you 2nd next element
    $i->peek(10); # gives you 10th next element

Note that `peek(1)` is the same as `peek()`.

Throws an exception if `$n` <= 0.

**NOTE:** Before version 0.03 this method would throw an exception if called
out of bounds. I decided this was not a good practice, as it made it difficult
to be able to peek ahead effectively. This is not the case when calling with an argument
that is <= 0 though, as it's clearly a sign of incorrect usage.

## current

This method can be used to get the current item in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the
last value dispensed by `next` or `get_next`.

## current\_index

This method can be used to get the current index in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the index
of the last value dispensed by `next` or `get_next`.

## currentIndex

Alternative name for current\_index

## reset

Reset index to allow iteration from the start

## get\_length

This is a basic accessor for getting the length of the array being iterated over.

## getLength

Alternative name for get\_length

# TODO

- Improve BiDirectional Test suite

    I want to test the back-and-forth a little more and make sure they work well with one another.

- Other Iterators

    Array::Iterator::BiDirectional::Circular, Array::Iterator::Skipable and
    Array::Iterator::BiDirectional::Skipable are just a few ideas I have had. I am going
    to hold off for now until I am sure they are actually useful.

# SEE ALSO

This module now includes several subclasses of Array::Iterator which add certain behaviors
to Array::Iterator, they are:

- `Array::Iterator::BiDirectional`

    Adds the ability to move backward and forward through the array.

- `Array::Iterator::Circular`

    When this iterator reaches the end of its list, it will loop back to the start again.

- `Array::Iterator::Reusable`

    This iterator can be reset to its beginning and used again.

The Design Patterns book by the Gang of Four, specifically the Iterator pattern.

Some of the interface for this class is based on the Java Iterator interface.

# OTHER ITERATOR MODULES

There are several on CPAN with the word Iterator in them.
Most of them are
actually iterators included inside other modules, and only really useful within that
parent module's context. There are, however, some other modules out there that are just
for pure iteration. I have provided a list below of the ones I have found if perhaps
you don't happen to like the way I do it.

- Tie::Array::Iterable

    This module ties the array, something we do not do. But it also makes an attempt to
    account for, and allow the array to be changed during iteration. It accomplishes this
    control because the underlying array is tied. As we all know, tie-ing things can be a
    performance issue, but if you need what this module provides, then it will likely be
    an acceptable compromise. Array::Iterator makes no attempt to deal with this mid-iteration
    manipulation problem.
    In fact,
    it is recommended to not alter your array with Array::Iterator,
    and if possible we will enforce this in later versions.

- Data::Iter

    This module allows for simple iteration over both hashes and arrays.
    It does it by
    importing several functions that can be used to loop over either type (hash or array)
    in the same way. It is an interesting module, it differs from Array::Iterator in
    paradigm (Array::Iterator is more OO) and intent.

- Class::Iterator

    This is essentially a wrapper around a closure-based iterator.
    This method can be very
    flexible, but at times is difficult to manage due to the inherent complexity of using
    closures. I actually was a closure-as-iterator fan for a while but eventually moved
    away from it in favor of the more plain vanilla means of iteration, like that found
    Array::Iterator.

- Class::Iter

    This is part of the Class::Visitor module and is a Visitor and Iterator extension to
    Class::Template.
    Array::Iterator is a standalone module that is not associated with others.

- **Data::Iterator::EasyObj**

    Data::Iterator::EasyObj makes your array of arrays into iterator objects.
    It also can
    further nest additional data structures including Data::Iterator::EasyObj
    objects.
    Array::Iterator is one-dimensional only and does not attempt to do many of
    the more advanced features of this module.

# ACKNOWLEDGEMENTS

- Thanks to Hugo Cornelis for pointing out a bug in `peek()`
- Thanks to Phillip Moore for providing the patch to allow single element iteration
through the hash-ref constructor parameter.

# ORIGINAL AUTHOR

stevan little, <stevan@iinteractive.com>

# ORIGINAL COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

[http://www.iinteractive.com](http://www.iinteractive.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# PREVIOUS MAINTAINER

Maintained 2017 to 2025 PERLANCAR

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-array-iterator at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Iterator](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Iterator).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Array::Iterator

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Array-Iterator](https://metacpan.org/dist/Array-Iterator)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Iterator](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Iterator)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Array-Iterator](http://matrix.cpantesters.org/?dist=Array-Iterator)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Array::Iterator](http://deps.cpantesters.org/?module=Array::Iterator)

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 24:

    Non-ASCII character seen before =encoding in 'Java’s'. Assuming UTF-8
