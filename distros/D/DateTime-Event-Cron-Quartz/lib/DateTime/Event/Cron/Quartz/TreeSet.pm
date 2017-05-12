package DateTime::Event::Cron::Quartz::TreeSet;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.05';

sub new {
    my $class = shift;

    my $list = shift;

    my $self = {
        _sorted => 0,
        _array  => defined $list ? $list : [],
        _index  => {}
    };

    return bless $self, $class;
}

sub size {
    return ( int @{ shift->{_array} } );
}

sub contains {
    my $self = shift;

    my $value = shift;

    return ( exists $self->{_index}->{$value} );
}

sub first_item {
    my $self = shift;

    if ( !$self->{_sorted} ) {
        $self->_sort;
    }

    return ( $self->size > 0 ? $self->{_array}->[0] : undef );
}

sub last_item {
    my $self = shift;
    if ( !$self->{_sorted} ) {
        $self->_sort;
    }

    return ( $self->size > 0 ? $self->{_array}->[ $self->size - 1 ] : undef );
}

sub add {
    my $self  = shift;
    my $value = shift;

    if ( !$self->contains($value) ) {
        push @{ $self->{_array} }, $value;
        $self->{_index}->{$value} = undef;
        $self->{_sorted} = 0;
    }

    return;
}

sub to_array {
    my $self = shift;
    
    if (!$self->{_sorted}) {
        $self->_sort;
    }
    
    return $self->{_array};
}

sub tail_set {
    my $self         = shift;
    my $from_element = shift;

    if ( !$self->{_sorted} ) {
        $self->_sort;
    }

    my $idx;

    if ( $self->contains($from_element) ) {

        # try to find in index
        $idx = $self->{_index}->{$from_element};
    }
    else {

        # find closest in array
        foreach my $val ( @{ $self->{_array} } ) {
            if ( $val >= $from_element ) {
                $idx = int $self->{_index}->{$val};
                CORE::last;
            }
        }
    }

    my $result_set;

    if ( defined $idx ) {
        my $size = $self->size - 1;

        $result_set = [ @{ $self->{_array} }[ $idx .. $size ] ];
    }

    return ( defined $result_set ? ( ref $self )->new($result_set) : undef );
}

# performs internal sorting and search index building
sub _sort {
    my $self = shift;

    if ( ( my $size = $self->size ) > 0 ) {
        $self->{_array} = [ CORE::sort { $a <=> $b } @{ $self->{_array} } ];

        # build search index
        foreach my $i ( 0 .. ( $size - 1 ) ) {
            $self->{_index}->{ $self->{_array}->[$i] } = $i;
        }
    }

    $self->{_sorted} = 1;

    return;
}

1;

__END__
=head1 NAME

DateTime::Event::Cron::Quartz::TreeSet - Ordered, unique set implementation.


=head1 AFFILIATION

This TreeSet implementation is a part of the L<DateTime::Event::Cron::Quartz>
distribution.


=head1 SYNOPSIS

    use DateTime::Event::Cron::Quartz::TreeSet;

    # TreeSet construction
    my $set = DateTime::Event::Cron::Quartz::TreeSet->new;

    # TreeSet constuction from the list of numeric values
    my $set = DateTime::Event::Cron::Quartz::TreeSet->new([30, 28, 15]);

    # adding an element to existing treeset
    $set->add(20);

    # getting last element from the set (greatest in the set)
    my $last = $set->last_item();

    # getting the first element from the set (lowest one)
    my $first = $set->first_item();

    # getting the set size
    my $size = $set->size();

    # getting the portion of the set whose elements are greater than or equal
    # to the parameter value
    my $tail_set = $set->tail_set(15);

    # check if the set contains an element
    if ($set->contains(40)) {
        print "set contains element with value of 40\n";
    }


=head1 DESCRIPTION

This package implements the set. This package guarantees that the sorted set
will be in ascending element order. Elements in this set are unique.
Package provides some functionality from
L<http://java.sun.com/j2se/1.4.2/docs/api/java/util/TreeSet.html>


=head1 SUBROUTINES/METHODS

=over

=item new($list)

Returns a DateTime::Event::Cron::Quartz::TreeSet object which
contains the list of values if $list parameter was provided

=item size()

Returns the number of elements in this set (its cardinality).

=item first_item()

Returns the first (lowest) element currently in this sorted set.

=item last_item()

Returns the last (gratest) element currently in this sorted set.

=item contains($element)

Returns true if this set contains the specified element.

=item tail_set($from_element)

Returns a view of the portion of this set whose
elements are greater than or equal to $from_element.
The returned sorted set supports all TreeSet methods.

=item to_array()

Returns an ordered array of elements


=back


=head1 INCOMPATIBILITIES

TreeSet works only with numbers. strings/objects are not allowed


=head1 BUGS AND LIMITATIONS

This is not a complete implementation of TreeSet. Only basic functionality
used by DateTime::Event::Cron::Quartz provided. Can not be used separately.


=head1 AUTHOR

Vadim Loginov <vadim.loginov@gmail.com>


=head1 COPYRIGHT AND LICENSE

Based on the source code and documentation of OpenSymphony
L<http://www.opensymphony.com/team.jsp> Quartz 1.4.2 project licensed
under the Apache License, Version 2.0

Copyright (c) 2009 Vadim Loginov.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 VERSION

0.05

=head1 SEE ALSO

DateTime::Event::Cron::Quartz(3),
L<http://java.sun.com/j2se/1.4.2/docs/api/java/util/TreeSet.html>
