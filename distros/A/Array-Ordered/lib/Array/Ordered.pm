package Array::Ordered;

use 5.006;
use strict;
use warnings FATAL => 'all';
use integer;
use subs qw( last unshift push shift pop sort );
use Scalar::Util qw( blessed );
use Carp;

=head1 NAME

Array::Ordered - Methods for handling ordered arrays

=cut

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT = qw( order );
our @EXPORT_OK = qw( order );

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Array::Ordered;
    
    # Export
    $array  = order [],       \&my_comparison;
    $array  = order \@array,  \&my_comparison;
    $array  = order $array,   \&other_comparison;
    
    # Utility
    $size   = $array->size;
    @items  = $array->clear;  # $array->size == 0
    
    # Strictly Ordered:
    $elem   = $array->find            $match;
              $array->insert          $item;
    $elem   = $array->find_or_insert  $match;
    $item   = $array->remove          $match;
    $pos    = $array->position        $match;
    unless(   $array->is_reduced  ) {
              $array->reduce;
    }
    
    # Unstrictly Ordered:
    $elem   = $array->first           $match;
    $elem   = $array->last            $match;
              $array->unshift         @items;
              $array->push            @items;
    $item   = $array->shift           $match;
    $item   = $array->pop             $match;
    $pos    = $array->first_position  $match;
    $pos    = $array->last_position   $match;
    $count  = $array->occurrences     $match;
    unless(   $array->is_sorted  ) {
              $array->sort;
    }
    
    # Multi-element:
    @elems  = $array->find_all        $match;
    @elems  = $array->heads;
    @elems  = $array->tails;
    @items  = $array->remove_all      $match;
    @items  = $array->shift_heads;
    @items  = $array->pop_tails;

=head1 DESCRIPTION

The purpose of the Array::Ordered module is to provide the means to access and modify arrays while keeping them sorted.

At the heart of this module are two symmetrical binary search algorithms:

=over

=item 1

The first returns the index of the first element equal to or greater than a matching argument. (possibly the array's size)

=item 2

The second returns the index of the last element equal to or less than a matching argument. (possibly -1)

=back

Elements are inserted and deleted from the ordered array using 'splice'.

=head2 TERMINOLOGY

=head3 Comparison Subroutine

A I<comparison subroutine> takes two arguments - each a scalar or a reference - and returns a numeric scalar:

=over

=item

Negative if the first argument should preceed the second (less than)

=item

Zero if they are equivalent (equal to)

=item

Positive if the first argument should follow the second (greater than)

=back

=head3 Equivalency Sequence

=begin html

<p>Consider an array <b>A</b> = &lt;X<sub>0</sub>, X<sub>1</sub>, X<sub>2</sub>, Y<sub>0</sub>, Z<sub>0</sub>, Z<sub>1</sub>&gt; sorted by the rule <i>C</i> such that:</p>

<ul style="list-style:none">
    <li><i>C</i> (X<sub>*</sub>, X<sub>*</sub>) = 0, 
        <i>C</i> (X<sub>*</sub>, Y<sub>*</sub>) < 0, 
        <i>C</i> (X<sub>*</sub>, Z<sub>*</sub>) < 0,</li>
    <li><i>C</i> (Y<sub>*</sub>, X<sub>*</sub>) > 0, 
        <i>C</i> (Y<sub>*</sub>, Y<sub>*</sub>) = 0, 
        <i>C</i> (Y<sub>*</sub>, Z<sub>*</sub>) < 0,</li>
    <li><i>C</i> (Z<sub>*</sub>, X<sub>*</sub>) > 0, 
        <i>C</i> (Z<sub>*</sub>, Y<sub>*</sub>) > 0, 
        <i>C</i> (Z<sub>*</sub>, Z<sub>*</sub>) = 0</li>
</ul>

<p>The array <b>A</b> has three <i>equivalency sequences</i>: <b>A</b><sub>X</sub> = &lt;X<sub>0</sub>, X<sub>1</sub>, X<sub>2</sub>&gt;, <b>A</b><sub>Y</sub> = &lt;Y<sub>0</sub>&gt;, and <b>A</b><sub>Z</sub> = &lt;Z<sub>0</sub>, Z<sub>1</sub>&gt;.

=end html

The length of every equivalency sequence in a strictly ordered array is 1.  Only an unstrictly ordered array can have longer equivalency sequences.

=head1 METHODS

I have used the following convention for naming variables:

=over

=item *

A variable is named C<$item> or C<@items> if it refers to data introduced into or removed from the ordered array.

=item *

A variable is named C<$elem> or C<@elems> if it refers to data accessed and remaining in the ordered array.

=item *

An argument is named C<$match> when it is used to fish out one or more equivalent elements from the array.

=back

=head2 Export

=head3 order

This method takes two arguments:

=over

=item 1

An array reference, and

=item 2

A reference to a comparison subroutine.

=back

The array reference is returned after being tied to the code reference for ordering, the array's contents are sorted, and the reference is blessed.

The method C<order> is exported implicitly.  The decision for this is due to the fact that none of the module's other methods are of any use without it.  Consider it this module's "C<new>" method.

    sub lencmp { length $_[0] <=> length $_[1] }
    
    $array = order [], \&lencmp;            # Empty array orded by 'lencmp'
    
    order $array, sub { $_[0] cmp $_[1] };  # Now ordered by 'cmp'
    
    $array = order [];                      # Okay: Default comparison is sub { 0 }
    
    my @items = { '3', '001', '02' };

    $array = order [@items], \&lencmp;      # Copy of @items ordered by '&lencmp':
                                            # @items is unchanged
    $array = order \@items,  \&lencmp;      # $array == \@items:
                                            # @items is sorted

=cut

my %CMPSUBS;

sub order {
    # @_ == ($self, $cmpsub);
    my  @valid    = (
        defined $_[0] ?
        blessed $_[0] ? $_[0]->isa('Array::Ordered') : ref $_[0] eq 'ARRAY' :
        '',
        defined $_[1] ? ref $_[1] eq 'CODE' : 1
    );

    unless ($valid[0] and $valid[1]) {
        my @msg = ('Array::Ordered::order');
        (defined $_[0]) or
            push @msg, 'missing argument';
        foreach my $i (0 .. 1) {
            (!$valid[$i] and defined $_[$i]) and
                push @msg, 'invalid argument '.(ref $_[0] || $_[0]);
        }
        croak join( ': ', @msg );
    }
      
    my ($self,
        $cmpsub)  = @_;
    (defined $cmpsub) or
        $cmpsub   = \&_default_cmpsub;

    (blessed $self) or bless $self;

    unless (exists $CMPSUBS{$self} and
            $CMPSUBS{$self} == $cmpsub) {
        $CMPSUBS{$self} = $cmpsub;
        $self->sort;
    }

    return $self;
}

=head2 Utility

=head3 size

Returns number of elements in referenced array.

    $size = $array->size;
    # Same as:
    $size = scalar @{$array};

=cut

sub size {
    return scalar( @{$_[0]} );
}

=head3 clear

Removes and returns all elements from the ordered array.

    @array_contained = $array->clear;
    # Same as:
    @array_contained = splice( @{$array}, 0, $array->size );

=cut

sub clear {
    return splice( @{$_[0]}, 0, scalar( @{$_[0]} ) );
}

=head2 Strictly Ordered

=head3 find

Alias for L<C<first>|/first>.

=head3 insert

Alias for L<C<push>|/push>.

=head3 find_or_insert

Returns first equivalent item if found, or inserts and returns a new item.

If no equivalent item is found, then:

=begin html

<ul style="list-style:none">
    <li>If a code reference is passed, its return value is inserted; otherwise,</li>
    <li>If a default value is passed, its value is inserted; otherwise,</li>
    <li>The method inserts the value of <code>$match</code>.</li>
</ul>

=end html

    $object = $array->find_or_insert( $match, \&constructor );
    $elem   = $array->find_or_insert( $match, $default );
    $elem   = $array->find_or_insert( $match );
    
    # Examples:
    $object = $array->find_or_insert( 'Delta', sub { My::NamedObject->new( 'Delta' ) } );
    $elem   = $array->find_or_insert( 'DELTA', 'Delta' );
    $elem   = $array->find_or_insert( 'Delta' );

Use C<find_or_insert> whenever possible! This is the only insertion method which verifies that the array is strictly ordered.

=cut

sub find_or_insert {
    # @_ == ($self, $match, $constr:undef);
    my ($self,
        $match,
        $constr)  = @_;
    my  $found    = $self->first( $match );

    unless (defined $found) {
        $found  = (defined $constr) ?
                  (ref $constr eq 'CODE') ? &{$constr} : $constr :
                  $match;
        $self->push( $found );
    }

    return $found;
}

=head3 remove

Alias for L<C<shift>|/shift>.

=head3 position

Alias for L<C<first_position>|/first_position>.

=head3 is_reduced

Returns C<1> if the array is strictly ordered, otherwise C<''>.

    $strictly = $array->is_reduced;

=cut

sub is_reduced {
    # @_ == ($self)
    my ($self)  = @_;
    my  $cmpsub = $CMPSUBS{$self};
    my  $size   = scalar @{$self};
    
    for (my $i = 1; $i < $size; $i++) {
        (&{$cmpsub}( $self->[$i-1], $self->[$i] ) < 0) or
            return '';
    }
    
    return 1;
}

=head3 reduce

Reduces the array into a strictly ordered array.

Only the last element of each equivalency sequence remains unless a C<TRUE> argument is passed, in which case only the first of each remains.

    $array->reduce;
    # Same as:
    $array->reduce( 0 );
    
    # Or use:
    
    my $preserve_first = 1;
    $array->reduce( $preserve_first );

=cut

sub reduce {
    # @_ == ($self, $preserve_first)
    my ($self,
        $preserve_first)  = @_;
    my  $cmpsub           = $CMPSUBS{$self};
    my  $size             = scalar @{$self};

    # Default behavior is FIFO: delete first unless otherwise specified
    my  $preserve_last    = $preserve_first ? 0 : 1;
    
    my $i = 1;
    while ($i < $size) {
        my  $cmp = &{$cmpsub}( $self->[$i-1], $self->[$i] );
        if ($cmp < 0) {
            $i++;
        }
        elsif ($cmp == 0) {
            splice( @{$self}, $i - $preserve_last, 1 );
            $size--;
        }
        else {
            my $item  = splice @{$self}, $i, 1;
            my $index = _search_down( $self, $item, $i - 2 );

            if ($index < 0 or
                &{$cmpsub}( $self->[$index], $item ) < 0) {
                _insert( $self, $item, $index + 1 );
            }
            else { # &{$cmpsub}( $item, $self->[$index] ) == 0
                $self->[$index] = $item unless ($preserve_first);
                $size--;
            }
        }
    }
}

=head2 Unstrictly Ordered

=head3 first

Returns first equivalent item or C<undef> if not found.

Optionally returns the position of the item or C<undef> if not found. (via C<wantarray>)

    $elem         = $array->first( $match );
    ($elem, $pos) = $array->first( $match );

=cut

sub first {
    # @_ == ($self, $match)
    my ($found,
        $equal,
        $index) = _find( @_, \&_search_up);
        
    $equal or
       ($found,
        $index) = (undef, undef);
    
    return  wantarray ? ($found, $index) : $found;
}

=head3 last

Returns last equivalent item or C<undef> if not found.

Optionally returns the position of the item or C<undef> if not found. (via C<wantarray>)

    $elem         = $array->last( $match );
    ($elem, $pos) = $array->last( $match );

=cut

sub last {
    # @_ == ($self, $match)
    my ($found,
        $equal,
        $index) = _find( @_, \&_search_down );
        
    $equal or
       ($found,
        $index) = (undef, undef);
    
    return  wantarray ? ($found, $index) : $found;
}

=head3 unshift

Adds item(s), prepending them to their equivalent peers.

    $array->unshift( $item );
    $array->unshift( @items );

=cut

sub unshift {
    # @_ == ($self, @items)
    my $self  = CORE::shift;

    foreach (@_) {
        _insert( $self, $_, _search_up( $self, $_ ) );
    }
}

=head3 push

Adds item(s), appending them to their equivalent peers.

    $array->push( $item );
    $array->push( @items );

=cut

sub push {
    # @_ == ($self, @items)
    my $self  = CORE::shift;

    foreach (@_) {
        _insert( $self, $_, _search_down( $self, $_ ) + 1 );
    }
}

=head3 shift

Removes and returns first equivalent item or C<undef> if not found.

    $item = $array->shift( $match );

=cut

sub shift {
    # @_ == ($self, $match)
    return _remove( @_, \&_search_up );
}

=head3 pop

Removes and returns last equivalent item or C<undef> if not found.

    $item = $array->pop( $match );

=cut

sub pop {
    # @_ == ($self, $match)
    return _remove( @_, \&_search_down );
}

=head3 first_position

Returns position of first equivalent item or C<undef> if not found.

    $pos = $array->first_position( $match );
    # Same as:
    $pos = ($array->first( $match ))[1];

=cut

sub first_position {
    return (first( @_ ))[1];
}

=head3 last_position

Returns position of last equivalent item or C<undef> if not found.

    $pos = $array->last_position( $match );
    # Same as:
    $pos = ($array->last( $match ))[1];

=cut

sub last_position {
    return (last( @_ ))[1];
}

=head3 occurrences

Returns number of elements equivalent to C<$match>.

    $count = $array->occurrences( $match );

=cut

sub occurrences {
    # @_ == ($self, $match)
    my ($found,
        $equal,
        $from)  = _find( @_, \&_search_up );

    return $equal ? _search_down( @_ ) - $from + 1 : 0;
}

=head3 is_sorted

Returns C<1> if the array is ordered, otherwise C<''>.

There is no need to call this method as long as the referenced array is modified only via the methods in this module.

    $ordered = $array->is_sorted;

=cut

sub is_sorted {
    # @_ == ($self)
    my ($self)  = @_;
    my  $cmpsub = $CMPSUBS{$self};
    my  $size   = scalar @{$self};
    
    for (my $i = 1; $i < $size; $i++) {
        (&{$cmpsub}( $self->[$i-1], $self->[$i] ) > 0) and
            return '';
    }
    
    return 1;
}

=head3 sort

Sorts the referenced array using its associated comparison subroutine.

There is no need to call this method as long as the referenced array is modified only via the methods in this module.

    $array->sort;

=cut

sub sort {
    # @_ == ($self)
    my ($self)  = @_;
    my  $cmpsub = $CMPSUBS{$self};
    my  $size   = scalar @{$self};

    for (my $i = 1; $i < $size; $i++) {
        if (&{$cmpsub}( $self->[$i], $self->[$i-1] ) < 0) {
            my $item  = $self->[$i];
            my $index = _search_down( $self, $item, $i - 2) + 1;
            for (my $j = $i; $j > $index; $j--) {
                $self->[$j] = $self->[$j-1];
            }
            $self->[$index] = $item;
        }
    }
}

=head2 Multi-element

=head3 find_all

Returns array of all items equivalent to C<$match>.

    @elems = $array->find_all( $match );

=cut

sub find_all {
    # @_ == ($self, $match)
    my ($found,
        $equal,
        $from)  = _find( @_, \&_search_up );

    return $equal ?  @{$_[0]}[$from .. _search_down( @_ )] : ();
}

=head3 heads

Returns a strictly ordered array containing the first of each equivalency sequence.

    @elems = $array->heads;

=cut

sub heads {
    # @_ == ($self)
    my ($self)  = @_;
    my  $size   = scalar( @{$self} );
    my  @heads;
    
    for (my $index = 0; $index < $size;
            $index = _search_down( $self, $heads[-1] ) + 1) {
        CORE::push @heads, $self->[$index];
    }

    return @heads;
}

=head3 tails

Returns a strictly ordered array containing the last of each equivalency sequence.

    @elems = $array->tails;

=cut

sub tails {
    # @_ == ($self)
    my ($self)  = @_;
    my  @tails;
    
    for (my $index = scalar( @{$self} ) - 1; $index >= 0;
            $index = _search_up( $self, $tails[0] ) - 1) {
        CORE::unshift @tails, $self->[$index];
    }

    return @tails;
}

=head3 remove_all

Removes all items equivalent to C<$match> and returns them as an array.

    @items = $array->remove_all( $match );

=cut

sub remove_all {
    # @_ == ($self, $match)
    my ($found,
        $equal,
        $from)  = _find( @_, \&_search_up );

    return $equal ?
        splice( @{$_[0]}, $from, _search_down( @_ ) - $from + 1 ) : ();
}

=head3 shift_heads

Removes the first of each equivalency sequence and returns them as a strictly ordered array.

    @items = $array->shift_heads;

=cut

sub shift_heads {
    # @_ == ($self)
    my ($self)  = @_;
    my  $size   = scalar( @{$self} );
    my  @heads;

    for (my $index = 0; $index < $size; $size--,
            $index = _search_down( $self, $heads[-1] ) + 1) {
        CORE::push @heads, splice( @{$self}, $index, 1 );
    }

    return @heads;
}

=head3 pop_tails

Removes the last of each equivalency sequence and returns them as a strictly ordered array.

    @items = $array->pop_tails;

=cut

sub pop_tails {
    # @_ == ($self)
    my ($self)  = @_;
    my  @tails;
    
    for (my $index = scalar( @{$self} ) - 1; $index >= 0;
            $index = _search_up( $self, $tails[0] ) - 1) {
        CORE::unshift @tails, splice( @{$self}, $index, 1 );
    }

    return @tails;
}

# Aliases

*find     = \&first;
*remove   = \&shift;
*insert   = \&push;
*position = \&first_position;

# Begin Private Methods

sub _find {
    my ($self,
        $match,
        $search)  = @_;
    my  $index    = &{$search}( $self, $match );
    my  $found    = $self->[$index];
    my  $equal    = defined $found ?
                    &{$CMPSUBS{$self}}( $match, $found ) == 0 :
                    '';

    return ( $found, $equal, $index );
}

sub _insert {
    my ($self,
        $item,
        $index) = @_;
    my  $size   = scalar @{$self};

    if ($index < $size / 2) {
        CORE::unshift @{$self}, splice( @{$self}, 0, $index, $item );
    }
    else {
        CORE::push @{$self}, splice( @{$self}, $index, $size - $index, $item );
    }
}

sub _remove {
    # @_ == ($self, $match, $search)
    my ($found,
        $equal,
        $index) = _find( @_ );

    return $equal ? splice( @{$_[0]}, $index, 1 ) : undef;
}

sub _search_up {
    my ($self,
        $match,
        $min)   = @_;
    my  $cmpsub = $CMPSUBS{$self};
    (defined $min) or
        $min    = 0;
    my  $max    = scalar @{$self};

    while ($min < $max and &{$cmpsub} ($match, $self->[$min]) > 0) {
        my $mid = $min + ($max - $min) / 2;
        if (&{$cmpsub} ($match, $self->[$mid]) > 0) {
            $min = $mid + 1;
        }
        else {
            $max = $mid;
        }
    }

    return $min;
}

sub _search_down {
    my ($self,
        $match,
        $max)   = @_;
    my  $cmpsub = $CMPSUBS{$self};
    (defined $max) or
        $max    = scalar @{$self} - 1;
    my  $min    = -1;

    while ($max > $min and &{$cmpsub} ($match, $self->[$max]) < 0) {
        my $mid = $max + ($min - $max) / 2;
        if (&{$cmpsub} ($match, $self->[$mid]) < 0) {
            $max = $mid - 1;
        }
        else {
            $min = $mid;
        }
    }

    return $max;
}

sub _default_cmpsub { 0 };

# End Private Methods

=head1 ACKNOWLEDGMENTS

This module's framework generated with L<C<module-starter>|Module::Starter>.

=head1 AUTHOR

S. Randall Sawyer, C<< <srandalls at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-array-ordered at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Ordered>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Array::Ordered

=head1 TODO

Write an XS version so that 'order' works syntactically like 'tie'. 
Write a module for handling large sorted arrays using a balanced binary tree as a back-end.

=head1 SEE ALSO

L<List::Util>, L<Scalar::Util>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 S. Randall Sawyer. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;

__END__

# End of Array::Ordered
