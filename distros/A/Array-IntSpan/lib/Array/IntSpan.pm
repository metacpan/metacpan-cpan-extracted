#
# This file is part of Array-IntSpan
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
##########################################################################
#
# Array::IntSpan - a Module for handling arrays using IntSpan techniques
#
# Author: Toby Everett, Dominique Dumont
#
##########################################################################
# Copyright 2003-2004,2010,2014 Dominique Dumont.  All rights reserved.
# Copyright 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic 2.0 License. See
# https://www.perlfoundation.org/artistic-license-20.html
#
# For comments, questions, bugs or general interest, feel free to
# contact Dominique Dumont at ddumont@cpan.org
##########################################################################

use strict;
use warnings ;

package Array::IntSpan;
$Array::IntSpan::VERSION = '2.004';

sub min { my @a = sort {$a <=> $b} @_ ; return $a[0] ; }
sub max { my @a = sort {$b <=> $a} @_ ; return $a[0] ; }

sub new {
  my $class = shift;

  my $self = [@_];
  bless $self, $class;
  $self->_check_structure;
  return $self;
}

#internal function
sub search {
  my ($self,$start,$end,$index) = @_ ;

  # Binary search for the first element that is *entirely* before the
  # element to be inserted
  while ($start < $end) {
    my $mid = int(($start+$end)/2);
    if ($self->[$mid][1] < $index) {
      $start = $mid+1;
    } else {
      $end = $mid;
    }
  }
  return $start ;
}

# clear the range. Note the the $self ref is preserved
sub clear {
    my $self = shift;
    @$self = () ;
}

sub set_range_as_string {
    my $self = shift;
    my $str = shift;

    $str =~ s/\s//g;

    foreach my $substr (split /,/, $str) {
        my @range = $substr =~ /-/ ? split /-/,$substr : ($substr) x 2;
        $self->set_range(@range, @_);
    }
}

sub set {
    my $self = shift;
    my $idx = shift;

    $self->set_range($idx, $idx, @_);
}

sub set_range {
  my $self = shift;

  #Test that we were passed appropriate values
  @_ == 3 or @_ == 4 or
    croak("Array::IntSpan::set_range should be called with 3 values and an ".
          "optional code ref.");
  $_[0] <= $_[1] or
      croak("Array::IntSpan::set_range called with bad indices: ".
            "$_[0] and $_[1].");

  not defined $_[3] or ref($_[3]) eq 'CODE' or
    croak("Array::IntSpan::set_range called without 4th parameter ".
          "set as a sub ref");

  my ($offset,$length,@list) = $self -> get_splice_parms(@_) ;

  #print "splice $offset,$length,@list\n";
  splice @$self, $offset,$length,@list ;

  return $length ? 1 : 0 ;
}

# not well tested or documented. May be useless...
sub check_clobber {
  my $self = shift;

  my @clobbered = $self->clobbered_items(@_) ;

  map {warn "will clobber @$_ with @_\n" ;} @clobbered ;

  return @clobbered ;
}

sub get_element
  {
    my ($self,$idx) = @_;
    my $ref = $self->[$idx] ;
    return () unless defined $ref ;
    return @$ref ;
  }

# call-back:
# filler (start, end)
# copy (start, end, payload )
# set (start, end, payload)

sub get_range {
  my $self = shift;
  #my($new_elem) = [@_];
  my ($start_elem,$end_elem, $filler, $copy, $set) = @_ ;

  $copy = sub{$_[2];} unless defined $copy ;

  my $end_range = $#{$self};
  my $range_size = @$self ; # nb of elements

  # Before we binary search, first check if we fall before the range
  if ($end_range < 0 or $self->[$end_range][1] < $start_elem)
    {
      my @arg = ref($filler) ?
        ([$start_elem,$end_elem,&$filler($start_elem,$end_elem)]) :
          defined $filler ? ([@_]) : () ;
      push @$self, @arg if @arg;
      return ref($self)->new(@arg) ;
    }

  # Before we binary search, first check if we fall after the range
  if ($end_elem < $self->[0][0])
    {
      my @arg = ref($filler) ?
        ([$start_elem,$end_elem,&$filler($start_elem,$end_elem)]) :
          defined $filler ? ([@_]) : () ;
      unshift @$self, @arg  if @arg;
      return ref($self)->new(@arg) ;
    }

  my $start = $self->search(0,     $range_size,  $start_elem) ;
  my $end   = $self->search($start,$range_size,  $end_elem) ;

  my $start_offset = $start_elem - $self->[$start][0] ;
  my $end_offset   = defined $self->[$end] ?
    $end_elem - $self->[$end][0] : undef ;

  #print "get_range: start $start, end $end, start_offset $start_offset";
  #print ", end_offset $end_offset" if defined $end_offset ;
  #print "\n";

  my @extracted ;
  my @replaced ;
  my $length = 0;

  # handle the start
  if (defined $filler and $start_offset < 0)
    {
      my $e = min ($end_elem, $self->[$start][0]-1) ;
      my $new = ref($filler) ? &$filler($start_elem, $e) : $filler ;
      my @a = ($start_elem, $e, $new) ;
      # don't use \@a, as we don't want @extracted and @replaced to
      # point to the same memory area. But $new must point to the same
      # object
      push @extracted, [ @a ] ;
      push @replaced,  [ @a ] ;
    }

  if ($self->[$start][0] <= $end_elem)
    {
      my $s = max ($start_elem,$self->[$start][0]) ;
      my $e = min ($end_elem, $self->[$start][1]) ;
      my $payload = $self->[$start][2] ;
      if ($self->[$start][0] < $s)
        {
          my $s1 = $self->[$start][0];
          my $e1 = $s - 1 ;
          push @replaced, [$s1, $e1 , &$copy($s1,$e1,$payload) ];
        }
      # must duplicate the start, end variable
      push @extracted, [$s, $e, $payload];
      push @replaced, [$s, $e, $payload];
      if ($e < $self->[$start][1])
        {
          my $s3 = $e+1 ;
          my $e3 = $self->[$start][1] ;
          push @replaced, [$s3, $e3, &$copy($s3, $e3,$payload) ] ;
        }
      &$set($s,$e, $payload) if defined $set ;
      $length ++ ;
    }

  # handle the middle if any
  if ($start + 1 <= $end -1 )
    {
      #print "adding " ;
      foreach my $idx ( $start+1 .. $end - 1)
        {
          #print "idx $idx," ;
          if (defined $filler)
            {
              my $start_fill = $self->[$idx-1][1]+1 ;
              my $end_fill = $self->[$idx][0]-1 ;
              if ($start_fill <= $end_fill)
                {
                  my $new = ref($filler) ? &$filler($start_fill, $end_fill)
                    : $filler ;
                  push @extracted, [$start_fill, $end_fill, $new] ;
                  push @replaced,  [$start_fill, $end_fill, $new];
                }
            }
          push @extracted, [@{$self->[$idx]}];
          push @replaced , [@{$self->[$idx]}];
          $length++ ;
        }
      #print "\n";
    }

  # handle the end
  if ($end > $start)
    {
      if (defined $filler)
        {
          # must add end element filler
          my $start_fill = $self->[$end-1][1]+1 ;
          my $end_fill = (not defined $end_offset or $end_offset < 0) ?
            $end_elem :  $self->[$end][0]-1 ;
          if ($start_fill <= $end_fill)
            {
              my $new = ref($filler) ? &$filler($start_fill, $end_fill) :
                $filler ;
              push @extracted, [$start_fill, $end_fill, $new] ;
              push @replaced,  [$start_fill, $end_fill, $new];
            }
        }

      if (defined $end_offset and $end_offset >= 0)
        {
          my $payload = $self->[$end][2] ;
          my $s = $self->[$end][0] ;
          my @a = ($s,$end_elem, $payload) ;
          push @extracted, [@a];
          push @replaced , [@a];
          if ($end_elem < $self->[$end][1])
            {
              my $s2 = $end_elem + 1 ;
              my $e2 = $self->[$end][1] ;
              push @replaced , [$s2, $e2, &$copy($s2,$e2,$payload)];
            }
          &$set($s,$end_elem, $payload) if defined $set ;
          $length++ ;
        }
    }

  if (defined $filler)
    {
      splice (@$self, $start,$length , @replaced) ;
    }

  my $ret = ref($self)->new(@extracted) ;
  return $ret ;
}

sub clobbered_items {
  my $self = shift;
  my($range_start,$range_stop,$range_value) = @_;

  my $item = $self->get_range($range_start,$range_stop) ;

  return   grep {$_->[2] ne $range_value} @$item ;
}


# call-back:
# set (start, end, payload)
sub consolidate {
  my ($self,$bottom,$top,$set) = @_;

  $bottom = 0 if (not defined $bottom or $bottom < 0 );
  $top = $#$self if (not defined $top or $top > $#$self) ;

  #print "consolidate from $top to $bottom\n";

  for (my $i= $top; $i>0; $i--)
    {
      if ($self->[$i][2] eq $self->[$i-1][2] and
          $self->[$i][0] == $self->[$i-1][1]+1 )
        {
          #print "consolidate splice ",$i-1,",2\n";
          my ($s,$e,$p) = ($self->[$i-1][0], $self->[$i][1], $self->[$i][2]);
          splice @$self, $i-1, 2, [$s, $e, $p] ;
          $set->($s,$e,$p) if defined $set ;
        }
    }

}

sub set_consolidate_range {
  my $self = shift;

  #Test that we were passed appropriate values
  @_ == 3 or @_ == 5 or
    croak("Array::IntSpan::set_range should be called with 3 values ".
          "and 2 optional code ref.");
  $_[0] <= $_[1] or
      croak("Array::IntSpan::set_range called with bad indices: $_[0] and $_[1].");

  not defined $_[3] or ref($_[3]) eq 'CODE' or
    croak("Array::IntSpan::set_range called without 4th parameter set as a sub ref");

  my ($offset,$length,@list) = $self -> get_splice_parms(@_[0,1,2,3]) ;

  #print "splice $offset,$length\n";
  splice @$self, $offset,$length,@list ;
  my $nb = @list ;

  $self->consolidate($offset - 1 , $offset+ $nb , $_[4]) ;

  return $length ? 1 : 0 ;#($b , $t ) ;

}

# get_range_list
# scalar context -> return a string
# list context => returns list of list

sub get_range_list {
    my ($self, %options) = @_;
    if (wantarray) {
        return map { [ @$_[0,1] ] } @$self;
    }
    else {
        return join ', ' , map {
            my ($a,$b) =  @$_;
                  $a == $b ? $a
                : $a+1==$b ? join(', ',$a,$b)
                :            join('-',$a,$b);
        } @$self;
    }
}

# internal function
# call-back:
# copy (start, end, payload )
sub get_splice_parms {
  my $self = shift;
  my ($start_elem,$end_elem,$value,$copy) = @_ ;

  my $end_range = $#{$self};
  my $range_size = @$self ; # nb of elements

  #Before we binary search, we'll first check to see if this is an append operation
  if ( $end_range < 0 or
      $self->[$end_range][1] < $start_elem
     )
    {
      return defined $value ? ( $range_size, 0, [$start_elem,$end_elem,$value]) :
        ($range_size, 0) ;
    }

  # Check for prepend operation
  if ($end_elem < $self->[0][0] ) {
    return defined $value ? ( 0 , 0, [$start_elem,$end_elem,$value]) : (0,0);
  }

  #Binary search for the first element after the last element that is entirely
  #before the element to be inserted (say that ten times fast)
  my $start = $self->search(0,     $range_size,  $start_elem) ;
  my $end   = $self->search($start,$range_size,  $end_elem) ;

  my $start_offset = $start_elem - $self->[$start][0] ;
  my $end_offset   = defined $self->[$end] ?
    $end_elem - $self->[$end][0] : undef ;

  #print "get_splice_parms: start $start, end $end, start_offset $start_offset";
  #print ", end_offset $end_offset" if defined $end_offset ;
  #print "\n";

  my @modified = () ;

  #If we are here, we need to test for whether we need to frag the
  #conflicting element
  if ($start_offset > 0) {
    my $item = $self->[$start][2] ;
    my $s = $self->[$start][0] ;
    my $e = $start_elem-1 ;
    my $new = defined($copy) ? $copy->($s,$e,$item) : $item ;
    push @modified ,[$s, $e, $new ];
  }

  push @modified, [$start_elem,$end_elem,$value] if defined $value ;

  #Do a fragmentation check
  if (defined $end_offset
      and $end_offset >= 0
      and $end_elem < $self->[$end][1]
     ) {
    my $item = $self->[$end][2] ;
    my $s = $end_elem+1 ;
    my $e = $self->[$end][1] ;
    my $new = defined($copy) ? $copy->($s,$e,$item) : $item ;
    push @modified , [$s, $e, $new] ;
  }

  my $extra =  (defined $end_offset and $end_offset >= 0) ? 1 : 0 ;

  return ($start, $end - $start + $extra , @modified);
}

sub lookup {
  my $self = shift;
  my($key) = @_;

  my($start, $end) = (0, $#{$self});
  return undef unless $end >= 0 ; # completely empty span

  while ($start < $end) {
    my $mid = int(($start+$end)/2);
    if ($self->[$mid][1] < $key) {
      $start = $mid+1;
    } else {
      $end = $mid;
    }
  }
  if ($self->[$start]->[0] <= $key && $self->[$start]->[1] >= $key) {
    return $self->[$start]->[2];
  }
  return undef;
}

sub _check_structure {
  my $self = shift;

  return unless $#$self >= 0;

  foreach my $i (0..$#$self) {
    @{$self->[$i]} == 3 or
        croak("Array::IntSpan::_check_structure failed - element $i lacks 3 entries.");
    $self->[$i][0] <= $self->[$i][1] or
        croak("Array::IntSpan::_check_structure failed - element $i has bad indices.");
    if ($i > 0) {
      $self->[$i-1][1] < $self->[$i][0] or
          croak("Array::IntSpan::_check_structure failed - element $i (",
                ,$self->[$i][0],",",$self->[$i][1],
                ") doesn't come after previous element (",
                $self->[$i-1][0],",",$self->[$i-1][1],")");
    }
  }
}

#The following code is courtesy of Mark Jacob-Dominus,
sub croak {
  require Carp;
  no warnings 'redefine' ;
  *croak = \&Carp::croak;
  goto &croak;
}

1;

__END__

=head1 NAME

Array::IntSpan - Handles arrays of scalars or objects using integer ranges

=head1 SYNOPSIS

  use Array::IntSpan;

  my $foo = Array::IntSpan->new([0, 59, 'F'], [60, 69, 'D'], [80, 89, 'B']);

  print "A score of 84% results in a ".$foo->lookup(84).".\n";
  unless (defined($foo->lookup(70))) {
    print "The grade for the score 70% is currently undefined.\n";
  }

  $foo->set_range(70, 79, 'C');
  print "A score of 75% now results in a ".$foo->lookup(75).".\n";

  $foo->set_range(0, 59, undef);
  unless (defined($foo->lookup(40))) {
    print "The grade for the score 40% is now undefined.\n";
  }

  $foo->set_range(87, 89, 'B+');
  $foo->set_range(85, 100, 'A');
  $foo->set_range(100, 1_000_000, 'A+');

=head1 DESCRIPTION

C<Array::IntSpan> brings the speed advantages of C<Set::IntSpan>
(written by Steven McDougall) to arrays.  Uses include manipulating
grades, routing tables, or any other situation where you have mutually
exclusive ranges of integers that map to given values.

The new version of C<Array::IntSpan> is also able to consolidate the
ranges by comparing the adjacent values of the range. If 2 adjacent
values are identical, the 2 adjacent ranges are merged.

=head1 Ranges of objects

C<Array::IntSpan> can also handle objects instead of scalar values.

But for the consolidation to work, the payload class must overload the
C<"">, C<eq> and C<==> operators to perform the consolidation
comparisons.

When a get_range method is called to a range of objects, it will
return a new range of object referencess. These object references
points to the objects stored in the original range. In other words the
objects contained in the returned range are B<not> copied.

Thus if the user calls a methods on the objects contained in the
returned range, the method is actually invoked on the objects stored
in the original range.

When a get_range method is called on a range of objects, several
things may happen:

=over

=item *

The get_range spans empty slots. By default the returned range will
skip the empty slots. But the user may provide a callback to create
new objects (for instance). See details below.

=item *

The get_range splits existing ranges. By default, the split range will
contains the same object reference. The user may provide callback to
perform the object copy so that the split range will contains
different objects. See details below.

=back

=head1 Ranges specified with integer fields

=over

=item *

C<Array::IntSpan::IP> is also provided with the distribution.  It lets
you use IP addresses in any of three forms (dotted decimal, network
string, and integer) for the indices into the array.  See the POD for
that module for more information. See L<Array::IntSpan::IP> for
details.

=item *

C<Array::IntSpan::Fields> is also provided with the distribution. It
let you specify an arbitrary specification to handle ranges with
strings made of several integer separared by dots (like IP addresses
of ANSI SS7 point codes). See L<Array::IntSpan::Fields> for details.

=back


=head1 METHODS

=head2 new (...)

The C<new> method takes an optional list of array elements.  The
elements should be in the form C<[start_index, end_index, value]>.
They should be in sorted order and there should be no overlaps.  The
internal method C<_check_structure> will be called to verify the data
is correct.  If you wish to avoid the performance penalties of
checking the structure, you can use C<Data::Dumper> to dump an object
and use that code to reconstitute it.

=head2 clear

Clear the range.

=head2 set_range (start, end, value [, code ref] )

This method takes three parameters - the C<start_index>, the
C<end_index>, and the C<value>.  If you wish to erase a range, specify
C<undef> for the C<value>.  It properly deals with overlapping ranges
and will replace existing data as appropriate.  If the new range lies
after the last existing range, the method will execute in O(1) time.
If the new range lies within the existing ranges, the method executes
in O(n) time, where n is the number of ranges. It does not consolidate
contiguous ranges that have the same C<value>.

If you have a large number of inserts to do, it would be beneficial to
sort them first.  Sorting is O(n lg(n)), and since appending is O(1),
that will be considerably faster than the O(n^2) time for inserting n
unsorted elements.

The method returns C<0> if there were no overlapping ranges and C<1>
if there were.

The optional code ref is called back when an existing range is
split. For instance if the original range is C<[0,10,$foo_obj]> and
set_range is called with C<[5,7,$bar_obj']>, the callback will be called
twice:

 $callback->(0, 4,$foo_obj)
 $callback->(8,10,$foo_obj)

It will be the callback responsability to make sure that the range
C<0-4> and C<7-10> holds 2 I<different> objects.

=head2 set( index,  value [, code ref] )

Set a single value. This may split an existing range. Actually calls:

 set_range( index, index, value [, code ref] )

=head2 set_range_as_string ( index,  string [, code ref] )

Set one one several ranges specified with a string. Ranges are separated by "-".
Several ranges can be specified with commas.

Example:

  set_range_as_string( '1-10,13, 14-20', 'foo')

White space are ignored.

=head2 get_range (start, end [, filler | undef , copy_cb [, set_cb]])

This method returns a range (actually an Array::IntSpan object) from
C<start> to C<end>.

If C<start> and C<end> span empty slot in the original range,
get_range will skip the empty slots. If a C<filler> value is provided,
get_range will fill the slots with it.

 original range    : [2-4,X],[7-9,Y],[12-14,Z]
 get_range(3,8)    : [3-4,X],[7-8,Y]
 get_range(2,10,f) : [3-4,X],[5-6,f],[7-8,Y]

If the C<filler> parameter is a CODE reference, the filler value will
be the one returned by the sub ref. The sub ref is invoked with
C<(start,end)>, i.e. the range of the empty span to fill
(C<get_range(5,6)> in the example above). When handling object, the
sub ref can invoke an object constructor.

If C<start> or C<end> split an original range in 2, the default
behavior is to copy the value or object ref contained in the original
range:

 original range     : [1-4,X]
 split range        : [1-1,X],[2-2,X],[3-4,X]
 get_range(2)       : [2-2,X]

If the original range contains object, this may lead to
disapointing results. In the example below the 2 ranges contains
references (C<obj_a>) that points to the same object:

 original range     : [1-4,obj_a]
 split range        : [1-1,obj_a],[2-2,obj_a],[3-4,obj_a]
 get_range(2)       : [2-2,obj_a]

Which means that invoking a method on the object returned by
C<get_range(2)> will also be invoked on the range 1-4 of the original
range which may not be what you want.

If C<get_range> is invoked with a copy parameter (actually a code
reference), the result of this routine will be stored in the split
range I<outside> of the get_range:

 original range     : [1-4,X]
 get_range(2)       : [2-2,X]
 split range        : [1-1,copy_of_X],[2-2,X],[3-4,copy_of_X]

When dealing with object, the sub ref should provide a copy of the object:

 original range     : [1-4,obj_a]
 get_range(2)       : [2-2,obj_a]
 split range        : [1-1,obj_a1],[2-2,obj_a],[3-4,obj_a2]

Note that the C<obj_a> contained in the C<split range> and the
C<obj_a> contained in the returned range point to the I<same object>.

The sub ref is invoked with C<(start,end,obj_a)> and is expected to
return a copy of C<obj_a> that will be stored in the split ranges. In
the example above, 2 different copies are made: C<obj_a1> and
C<obj_a2>.

Last, a 3rd callback may be defined by the user: the C<set_cb>. This
callback will be used when the range start or end that holds an object
changes. In the example above, the C<set_cb> will be called this way:

 $obj_a->&$set_cb(2,2) ;

As a matter of fact, the 3 callback can be used in the same call. In
the example below, C<get_range> is invoked with 3 subs refs:
C<\&f,\&cp,\&set>:

 original range     : [1-4,obj_a],[7-9,obj_b]
 get_range(3-8,...) : [3-4,obj_a],[5-6,obj_fill],[7-8,obj_b]
 split range        : [1-2,obj_a1], [3-4,obj_a],[5-6,obj_fill],
                      [7-8,obj_b],[9-9,obj_b1]

To obtain this, get_range will perform the following calls:

 $obj_fill = &f ;
 $obj_a1 = &cp(5,6,obj_a);
 &set(3,4,$obj_a) ;
 $obj_b = &cp(9,9,obj_b) ;
 &set(7-8,obj_b) ;

=head2 get_range_list

In scalar context, returns a list of range in a string like: "C<1-5,7,9-11>".

In list context retunrs a list of list, E.g. C< ( [1,5], [7,7], 9,11])>.

=head2 lookup( index )

This method takes as a single parameter the C<index> to look up.  If
there is an appropriate range, the method will return the associated
value.  Otherwise, it returns C<undef>.

=head2 get_element( element_number )

Returns an array containing the Nth range element:

 ( start, end, value )

=head2 consolidate( [ bottom, top , [ set_cb ]] )

This function scans the range from the range index C<bottom> to C<top>
and compare the values held by the adjacent ranges. If the values are
identical, the adjacent ranges are merged.

The comparison is made with the C<==> operator. Objects stored in the
range B<must> overload the C<==> operator. If not, the comparison is
made with the standard stringification of an object and the merge
never happens.

If provided, the C<set_cb> is invoked on the contained object
after 2 ranges are merged.

For instance, if C<"$obj_a" eq "$obj_b">:

 original range is            : [1-4,obj_a],[5-9,obj_b]
 consolidate(0,1,\&set) yields: [1-9,obj_a]

And C<consolidate> performs this call:

 $set->(1,9,obj_a) ;

Consolidate the whole range when called without parameters.

=head1 CONTRIBUTORS

=over

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 AUTHORS

=over

=item *

Toby Everett, teverett@alascom.att.com

=item *

Dominique Dumont, ddumont@cpan.org

=back

Copyright (c) 2000 Toby Everett.
Copyright (c) 2003-2004,2014,2020 Dominique Dumont.
All rights reserved.  This program is free software.

This module is distributed under the Artistic 2.0 License. See
https://www.perlfoundation.org/artistic-license-20.html

=cut

