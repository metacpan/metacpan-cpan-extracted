
#
# Algorithm::ChooseSubsets by Brian Duggan <bduggan@matatu.org>
#
# Copyright (c) 2002 Brian Duggan.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Algorithm::ChooseSubsets;


use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

=head1 NAME

Algorithm::ChooseSubsets - OO interface to iterate through subsets of a list.

=head1 SYNOPSIS

  use Algorithm::ChooseSubsets

  # Choose all subsets of a set
  $i = new Algorithm::ChooseSubsets($n);  
  $i = new Algorithm::ChooseSubsets(\@set);  
  $i = new Algorithm::ChooseSubsets(set=>\@set);

  # Choose subsets of a fixed size $k
  $i = new Algorithm::ChooseSubsets($n,$k);
  $i = new Algorithm::ChooseSubsets(\@set,$k);
  $i = new Algorithm::ChooseSubsets(set=>\@set, size=>$k);

  # Choose subsets of sizes greater than or equal to k
  $i = new Algorithm::ChooseSubsets($n,$k,1);
  $i = new Algorithm::ChooseSubsets(\@set,$k,1);
  $i = new Algorithm::ChooseSubsets(set=>\@set, size=>$k, all=>1);

  while ($x = $i->next) {
    # Do something with @$x
    }

  $i->reset;        # return to the first subset.

=head1 DESCRIPTION

    "Subsets" in this context refers to lists with elements taken
from the original list, and in the same order as the elements in the
original list.  After creating the object, subsequent calls to next()
will return the next such list in lexicographic order (where the alphabet
is the original list).

    If K is specified, only subsets of that size will be returned.  If K
is omitted, all subsets will be returned, beginning with the empty set
and ending with the entire set.  If the 'all' flag and a value for 'K' are
specified, subsets of size greater than or equal to K will be returned.

    If a number, N, is used instead of a list, the list is taken to
be [0..N-1].

=head1 EXAMPLES

  # Print ab ac ad ae bc bd be cd ce de
  $i = new Algorithm::ChooseSubsets([qw(a b c d e)],2);
  print @$x," " while ($x = $i->next);

  # Print all 2,598,960 possible poker hands.
  $i = new Algorithm::ChooseSubsets (\@cards, 5);
  print @$hand,"\n" while ($hand = $i->next);

  # Print ::0:1:2:01:02:12:012
  $i = new Algorithm::ChooseSubsets(3);
  print ":",@$j while ($j = $i->next);

=head1 NOTES

    For a fixed K, next() will return a value N! / (K! * [N-K]!) times.
    For all subsets and a list of size N, it'll return a value 2**N times.

=head1 AUTHOR

Brian Duggan <bduggan@matatu.org>

=head1 SEE ALSO

perl(1).

=cut

sub new {
    my $class = shift;
    my %args;

    if (ref($_[0]) eq 'ARRAY') { # e.g. ( [0..9], 5)
        %args = ( 'set' => $_[0], 'size' => $_[1], 'all' => $_[2] );
    } elsif ($_[0] =~ /^\d+$/) { # e.g. ( 10, 5)
        %args = ( 'set' => [ 0 .. $_[0]-1 ], 'size' => $_[1], 'all' => $_[2] );
    } else {                     # ( set => [0..9], size => 5)
        %args = @_;
    }

    if (!defined($args{'size'})) {
        $args{'size'} = 0;
        $args{'all'} = 1;
    }

    bless (+{
        _size => ($args{'size'}),       # size of the subsets we are returning
        _original_size => ($args{'size'}),       # ditto, for resetting purposes
        _set => ($args{'set'} || croak "Missing set"),     # the set
        _n => scalar(@{$args{'set'}}),  # size of the set
        _c => undef,                    # Current indexes to return.
        _all => $args{'all'}            # whether to do all or just one K.
    },$class);
}

#
# return the next subset.
#
sub next {
    my $self = shift;
    my ($n, $k, $c, $set) = @$self{qw(_n _size _c _set)};

    # First one?
    !defined($c) && return [ @$set[@{$self->{_c} = [0..$k-1]}]];  

    # Last one?
    my $last_one = (($k==0 && scalar(@$c)==0) || ($c->[0]==$n-$k)); 
    return undef if $last_one && !$self->{'_all'};
    if ($last_one && $self->{'_all'}) {
        $self->{'_size'}++;
        return undef if (++$k > $n);
        return [ @$set[@{$self->{_c} = [0..$k-1]}]];  
    }

    # impossible?
    return undef if ($k > $n);

    # Find the position to change.
    my $p = $k - 1;
    $p-- while ($p > 0 && $c->[$p] == $n-$k+$p);

    # Change that position, and all subsequent ones.
    @$c[$p..$k-1] = ($c->[$p]+1 .. $c->[$p] + $k-$p);

    # Set the internal state, and return the values.
    $self->{'_c'} = $c;
    return [@$set[@$c]];
}

#
# reset to the first subset.
#
sub reset {
    my $self = shift;
    $self->{_size} = $self->{_original_size};
    $self->{_c} = undef;
}

1;

