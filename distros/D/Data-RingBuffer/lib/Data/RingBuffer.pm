#!/usr/bin/perl
#made by: KorG
# vim: sw=4 ts=4 et cc=79 :

package Data::RingBuffer;

use 5.008;
use strict;
use warnings FATAL => 'all';
use Carp;

our $VERSION = '0.02';
$VERSION =~ tr/_//d;

# Add an element to the buffer
# args: $obj
sub push {
    if ($_[0]->{head} == $_[0]->{size}) {
        croak "Buffer overflow!" if exists $_[0]->{die_overflow};
        shift @{$_[0]->{buf}};
        $_[0]->{tail}-- if $_[0]->{tail} > 0;
    }

    push @{$_[0]->{buf}}, $_[1];

    $_[0]->{head}++ if $_[0]->{head} < $_[0]->{size};

    return $_[1];
}

# Get all elements in the buffer
sub getall {
    return $_[0]->{buf};
}

# Get next element from the buffer
sub get {
    my $rb = $_[0];
    return if $_[0]->{tail} >= $_[0]->{head};
    return $_[0]->{buf}->[$_[0]->{tail}++];
}

# OO ctor
# args: $size, (optional) { %options }
sub new {
    # Parse arguments
    croak "Buffer size not defined" unless defined $_[1];
    croak "Buffer size must be positive" unless $_[1] > 0;

    my %opts;
    if (ref $_[2] eq "HASH") {
        $opts{die_overflow} = undef if $_[2]->{die_overflow};
    }

    bless {
        buf => [],
        size => $_[1],
        head => 0,
        tail => 0,
        %opts,
    }, $_[0];
}

1; # End of Data::RingBuffer

__END__

=pod

=encoding utf8

=head1 NAME

Data::RingBuffer - A simple ring buffer data structure

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Ring buffer data structure could be used in a various environments, demanding
circular data storage or any kind of cyclic data caching.
There is a good implementation of arrays in Perl, which supports elements 
addition in any direction.
This module provides a simple wrapper over them. 

=head1 SUBROUTINES

=head2 new

C<$obj = Data::RingBuffer-E<gt>new($size[, $hashref])> is an object constructor
that will correctly initialize the object being created.

=over 4

=item C<$size> is a positive number of slots in the buffer.

=item C<$hashref> I<(optional)> is a hash with optional parameters.

=over 4

=item C<die_overflow> causes croak if the buffer overflows.

=back

=back

=head2 push

C<$obj-E<gt>push($element)> adds an C<$element> to the buffer.

=over 4

=item C<$element> is some scalar being inserted in the buffer.

=back

=head2 get

Get next C<$element> from the buffer.

=head2 getall

Get an arrayref of all the elements in the buffer.

=head1 AUTHOR

Sergei Zhmylev, C<E<lt>zhmylove@cpan.orgE<gt>>

=head1 BUGS

Please report any bugs or feature requests to official GitHub page at
L<https://github.com/zhmylove/data-ringbuffer>.
You also can use official CPAN bugtracker by reporting to
C<bug-data-ringbuffer at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-RingBuffer>.
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

