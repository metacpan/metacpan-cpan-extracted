# NAME

Data::RingBuffer - A simple ring buffer data structure

# SYNOPSIS

```perl
use Data::RingBuffer;

my $rb = Data::RingBuffer->new(4);
my $rb = Data::RingBuffer->new(4, { die_overflow => 1 });

$rb->push($obj1);
$rb->push($obj2);
$rb->push($obj3);
$obj1 = $rb->get();
$obj2 = $rb->get();
$rb->push($obj4);
$rb->push($obj5); # $obj1 removed from the buffer
$obj3 = $rb->get();
my $objs = $rb->getall(); # [ $obj2, $obj3, $obj4, $obj5 ]
```

# DESCRIPTION

Ring buffer data structure could be used in a various environments, demanding
circular data storage or any kind of cyclic data caching.
There is a good implementation of arrays in Perl, which supports elements 
addition in any direction.
This module provides a simple wrapper over them. 

# SUBROUTINES

## new

`$obj = Data::RingBuffer->new($size[, $hashref])` is an object constructor
that will correctly initialize the object being created.

- `$size` is a positive number of slots in the buffer.
- `$hashref` _(optional)_ is a hash with optional parameters.
    - `die_overflow` causes croak if the buffer overflows.

## push

`$obj->push($element)` adds an `$element` to the buffer.

- `$element` is some scalar being inserted in the buffer.

## get

Get next `$element` from the buffer.

## getall

Get an arrayref of all the elements in the buffer.

# AUTHOR

Sergei Zhmylev, `<zhmylove@cpan.org>`

# BUGS

Please report any bugs or feature requests to official GitHub page at
[https://github.com/zhmylove/data-ringbuffer](https://github.com/zhmylove/data-ringbuffer).
You also can use official CPAN bugtracker by reporting to
`bug-data-ringbuffer at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sergei Zhmylev.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
