# NAME

Data::RingBuffer::Time - Ring buffer data structure to keep time-series data

# SYNOPSIS

```perl
use Data::RingBuffer::Time;

my $rb = Data::RingBuffer::Time->new(4);

$rb->push($obj1);
$rb->push($obj2);
$rb->push($obj3);
$obj1 = $rb->get();
$obj2 = $rb->get();
$rb->push($obj4);
$rb->push($obj5); # $obj1 removed from the buffer
$obj3 = $rb->get();
my $objs = $rb->getall(); # [ $obj2, $obj3, $obj4, $obj5 ]

my $objs = $rb->getall($time); # ARRAYref to all objects added after $time
```

# DESCRIPTION

Sometimes it's necessary to use ring-buffers as a storage for time-series.
This module works just like [Data::RingBuffer](https://metacpan.org/pod/Data%3A%3ARingBuffer) and takes the same interface
semantics.  However for each element in the buffer it handles a timestamp of
their addition.  `getall()` is overloaded to support lower `$time` boundary
definition which is being used as a filter for `getall()` elements.

# SUBROUTINES

## new

`$obj = Data::RingBuffer::Time->new($size)` is an object constructor
that will correctly initialize the object being created.

- `$size` is a positive number of slots in the buffer.

## push

`$obj->push($element)` adds an `$element` to the buffer.

- `$element` is some scalar being inserted in the buffer.

## get

Get next `$element` from the buffer.

## getall

`$obj->getall($time)` gets an arrayref of all the elements in the buffer.

- `$time` _(optional)_ is an excluded lower time boundary.

# AUTHOR

Sergei Zhmylev, `<zhmylove@cpan.org>`

# BUGS

Please report any bugs or feature requests to official GitHub page at
[https://github.com/zhmylove/data-ringbuffer-time](https://github.com/zhmylove/data-ringbuffer-time).
You also can use official CPAN bugtracker by reporting to
`bug-data-ringbuffer-time at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer-Time](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer-Time).
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
