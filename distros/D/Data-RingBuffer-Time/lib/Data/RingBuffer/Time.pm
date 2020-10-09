#!/usr/bin/perl
#made by: KorG
# vim: sw=4 ts=4 et cc=79 :

package Data::RingBuffer::Time;

use 5.008;
use strict;
use warnings FATAL => 'all';
use Carp;
use Data::RingBuffer;

our $VERSION = '0.01';
$VERSION =~ tr/_//d;

BEGIN { our @ISA = 'Data::RingBuffer' };

# Add an element to the buffer
# args: $obj
sub push {
    $_[0]->[0]->push(time);
    $_[0]->[1]->push($_[1]);
    return $_[1];
}

# (internal) find index of first element with time
sub _find_index {
    my $idx = 0;
    my $buf = $_[0]->[0]->{buf};
    while ($idx <= $#$buf) {
        return $idx if $buf->[$idx] > $_[1];
        $idx++;
    }

    return undef;
}

# Get all elements in the buffer
# args: (optional) time
sub getall {
    if (defined $_[1]) {
        croak "Time must be positive" unless $_[1] >= 0;
        my $idx = $_[0]->_find_index($_[1]);
        return [] unless defined $idx;
        my $buf = $_[0]->[1]->{buf};
        return [@{$buf}[$idx .. $#$buf]];
    }
    return $_[0]->[1]->getall();
}

# Get next element from the buffer
sub get {
    $_[0]->[0]->get(); # handle tail movement
    $_[0]->[1]->get();
}

# OO ctor
# args: $size
sub new {
    bless [
        Data::RingBuffer->new($_[1]), # time storage
        Data::RingBuffer->new($_[1]), # obj storage
    ], $_[0];
}

1; # End of Data::RingBuffer::Time

__END__

=pod

=encoding utf8

=head1 NAME

Data::RingBuffer::Time - Ring buffer data structure to keep time-series data

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Sometimes it's necessary to use ring-buffers as a storage for time-series.
This module works just like L<Data::RingBuffer> and takes the same interface
semantics.  However for each element in the buffer it handles a timestamp of
their addition.  C<getall()> is overloaded to support lower C<$time> boundary
definition which is being used as a filter for C<getall()> elements.

=head1 SUBROUTINES

=head2 new

C<$obj = Data::RingBuffer::Time-E<gt>new($size)> is an object constructor
that will correctly initialize the object being created.

=over 4

=item C<$size> is a positive number of slots in the buffer.

=back

=head2 push

C<$obj-E<gt>push($element)> adds an C<$element> to the buffer.

=over 4

=item C<$element> is some scalar being inserted in the buffer.

=back

=head2 get

Get next C<$element> from the buffer.

=head2 getall

C<$obj-E<gt>getall($time)> gets an arrayref of all the elements in the buffer.

=over 4

=item C<$time> I<(optional)> is an excluded lower time boundary.

=back

=head1 AUTHOR

Sergei Zhmylev, C<E<lt>zhmylove@cpan.orgE<gt>>

=head1 BUGS

Please report any bugs or feature requests to official GitHub page at
L<https://github.com/zhmylove/data-ringbuffer-time>.
You also can use official CPAN bugtracker by reporting to
C<bug-data-ringbuffer-time at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer-Time>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sergei Zhmylev.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

