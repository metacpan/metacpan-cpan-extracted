package Data::RunningTotal;


use 5.005;
use strict;
use warnings;
use Carp;
use Data::RunningTotal::Item;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.03';

# Create a new Running Total object
sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my %opts = @_;

    croak("Missing required parameter 'dimensions'") if !exists($opts{dimensions});
    croak("'dimensions' paramter must be an array ref") if (ref($opts{dimensions}) ne "ARRAY");

    my @dimensions = @{$opts{dimensions}};

    # Remember the dimensions
    my %state = (dims    => \@dimensions,
                 numDims => scalar(@dimensions),
                 counts  => [],
                 pendingUpdates => {},
                 updatesPending => 0,
                );

    return bless(\%state);

}

# Increment the count for a specific point
sub inc {
  my ($self, $time, %opts) = @_;

  croak("Missing required parameter 'coords'") if !exists($opts{coords});
  croak("'coords' paramter must be an array ref") if (ref($opts{coords}) ne "ARRAY");

  my $weight = $opts{weight} || 1;

  if (scalar(@{$opts{coords}}) != $self->{numDims}) {
    croak("Expected $self->{numDims} coordinates, but ".scalar(@{$opts{coords}})." given");
  }
  
  $self->{updatesPending}++;
  push(@{$self->{pendingUpdates}{$time}}, [$weight, @{$opts{coords}}]);

}

# Decrement the count for a specific point
sub dec {
  my ($self, $time, %opts) = @_;

  croak("Missing required parameter 'coords'") if !exists($opts{coords});
  croak("'coords' paramter must be an array ref") if (ref($opts{coords}) ne "ARRAY");

  my $weight = ($opts{weight} || 1) * -1;

  if (scalar(@{$opts{coords}}) != $self->{numDims}) {
    croak("Expected $self->{numDims} coordinates, but ".scalar(@{$opts{coords}})." given");
  }
  
  $self->{updatesPending}++;
  push(@{$self->{pendingUpdates}{$time}}, [$weight, @{$opts{coords}}]);

}

# Create a new item that can be moved in the space
sub newItem {
  my ($self, %opts) = @_;
  my $weight = $opts{weight} || 1;
  return Data::RunningTotal::Item->new($self, $self->{numDims}, $weight);
}

# Get the count for a specific point or volume in time
# Note that the coords can be code refs
sub getValue {
  my ($self, $time, %opts) = @_;

  croak("Missing required parameter 'coords'") if !exists($opts{coords});
  croak("'coords' paramter must be an array ref") if (ref($opts{coords}) ne "ARRAY");

  $self->_applyPending();

  my $lastIdx           = $self->_findIndexForTime($time);
  my ($eligCoords, 
      $numPermutations) = $self->_getEligibleCoords(@{$opts{coords}});

  # It is possible that the user asked for a value that has never been seen
  return 0 if !defined $eligCoords;

  my $dimArrays    = $self->_getDimArrays($eligCoords, $lastIdx);

  # Do the real work
  return $self->_getValueWalkingBackwards($dimArrays, $numPermutations);

}

# Get a list of changes to the weight of each of the specified points/volumes
sub getChangeList {
  my ($self, %opts) = @_;

  croak("Missing required parameter 'coords'") if !exists($opts{coords});
  croak("'coords' paramter must be an array ref") if (ref($opts{coords}) ne "ARRAY");

  $self->_applyPending();

  my ($eligCoords, 
      $numPermutations) = $self->_getEligibleCoords(@{$opts{coords}});

  # It is possible that the user asked for a value that has never been seen
  return [] if !defined $eligCoords;

  my $dimArrays    = $self->_getDimArrays($eligCoords);

  # Do the real work
  return $self->_getListWalkingForwards($dimArrays, $opts{period}, $opts{start}, $opts{end});

}

# Pass in N change lists and it will combine them into a single 
# changelist with a time value and N following values
sub combineChangeList {
  my ($self, @lists) = @_;

  my @res;

  my $numLists = scalar(@lists);
  my @listIdxs;
  my @lastVals;
  for my $i (0 .. $numLists-1) {
    $listIdxs[$i] = 0;
    $lastVals[$i] = 0;
  }

  while(1) {
    my $minTime = $lists[0][$listIdxs[0]][0];
    for my $i (1 .. $numLists-1) {
      my $listTime = $lists[$i][$listIdxs[$i]][0];
      $minTime = $listTime if !defined $minTime || defined $listTime && $listTime < $minTime;
    }

    last if !defined $minTime;
    
    for my $i (0 .. $numLists-1) {
      my $listTime = $lists[$i][$listIdxs[$i]][0];
      if (defined $listTime && $listTime == $minTime) {
        $lastVals[$i] = $lists[$i][$listIdxs[$i]][1];
        $listIdxs[$i]++;
      }
    }
    push(@res, [$minTime, @lastVals]);
  }

  return \@res;

}


######################################################################
## Private Methods
######################################################################

# Just dump out the state - should be removed before prime time
sub _dumpState {
  my ($self) = @_;

  # print Dumper $self;

}

# Apply all the pending updates
sub _applyPending {
  my ($self) = @_;

  if ($self->{updatesPending} == 0) {
    return;
  }

  # Clean out last data
  @{$self->{counts}} = ();
  @{$self->{dimIdxs}} = ();

  my %last;
  my $idx = 0;
  foreach my $time (sort {$a <=> $b} keys(%{$self->{pendingUpdates}})) {
    foreach my $update (@{$self->{pendingUpdates}{$time}}) {
      my $tref = \%last;
      my $coords = $update;
      my $weight = shift(@{$coords});
      # map {$tref->{$_} = {} if !defined($tref->{$_}); $tref = $tref->{$_};} @{$coords};
      map {$tref = ($tref->{$_} ||= {});} @{$coords};
      $tref->{val} += $weight;
      push(@{$self->{counts}}, [$time, $tref->{val}, $tref->{lastIdx}]);
      $tref->{lastIdx} = $idx;
      foreach my $dim (0 .. $self->{numDims}-1) {
        push(@{$self->{dimIdxs}[$dim]{$coords->[$dim]}}, $idx);
      }
      $idx++;
    }
  }
  $self->{updatesPending} = 0;

}

# Look through the list of counts ordered by time and find the
# index for the specified time
sub _findIndexForTime {
  my ($self, $time) = @_;

  # just do a simple binary search to find the first entry that 
  # is greater than the time or the last entry that equals the time
  my $start = 0;
  my $end = scalar(@{$self->{counts}})-1;
  my $origEnd = $end;
  my $lastSmaller;
  my $lastEqual;

  my $notDone = 1;
  while ($notDone) {

    if ($start >= $end) {
      $notDone = 0;
    }
    my $idx = int(($end-$start)/2)+$start;

    if ($self->{counts}[$idx][0] < $time) {
      $lastSmaller = $idx;
      $start       = $idx+1;
    }
    elsif ($self->{counts}[$idx][0] == $time) {
      $lastEqual   = $idx;
      $start       = $idx+1;
    }
    else {
      $end         = $idx-1;
    }

  }

  return $lastEqual if defined $lastEqual;
  return $lastSmaller if defined $lastSmaller;
  return $origEnd;

}


# Go through all the possible coords and produce a list of lists of them
sub _getEligibleCoords {
  my ($self, @coordSels) = @_;

  my @res;
  my $permutations = 1;
  for my $i (0 .. $self->{numDims}-1) {
    my @elig;
    if (ref $coordSels[$i] eq "CODE") {
      # Call the code ref on each possible coordinate, collecting ones that return true
      foreach my $coord (keys(%{$self->{dimIdxs}[$i]})) {
        if (&{$coordSels[$i]}($coord)) {
          push(@elig, $coord);
        }
      }
    }
    elsif (!defined $coordSels[$i]) {
      # An undefined coordidate selector behaves like a wildcard
      # foreach my $coord (keys(%{$self->{dimIdxs}[$i]})) {
      #   push(@elig, $coord);
      # }
      push(@res, undef);
      $permutations *= scalar(keys(%{$self->{dimIdxs}[$i]}));
      next;
    }
    elsif (defined $self->{dimIdxs}[$i]{$coordSels[$i]}) {
      push(@elig, $coordSels[$i]);
    }

    if (scalar(@elig) == 0) {
      # No coords found for the selector - no value will be found
      return undef;
    }
    
    $permutations *= scalar(@elig);
    push(@res, \@elig);

  }

  return (\@res, $permutations);

}

# This will combine and sort all the selected coordinates into single
# arrays per dimension
sub _getDimArrays {
  my ($self, $eligibleCoords, $lastIdx) = @_;

  my @res;
  for my $i (0 .. $self->{numDims}-1) {
    if (!defined $eligibleCoords->[$i]) {
      # Do nothing - this indicates that all coordinates should be
      # included, which is what will happen if we don't include any
    }
    elsif (scalar(@{$eligibleCoords->[$i]}) > 1) {
      my @coordList;
      foreach my $coord (@{$eligibleCoords->[$i]}) {
        my $list = $self->{dimIdxs}[$i]{$coord};
        if (defined $lastIdx) {
          my $end = _binarySearch($list, $lastIdx);
          @coordList = (@coordList, @{$list}[0..$end]);
        }
        else {
          @coordList = (@coordList, @{$list});
        }
      }
      @coordList = sort {$a <=> $b} @coordList;
      push(@res, \@coordList);
    }
    else {
      if (defined $lastIdx) {
        my $end = _binarySearch($self->{dimIdxs}[$i]{$eligibleCoords->[$i][0]}, $lastIdx);
        my @subset = @{$self->{dimIdxs}[$i]{$eligibleCoords->[$i][0]}}[0..$end]; 
        push(@res, \@subset);
      }
      else {
        push(@res, $self->{dimIdxs}[$i]{$eligibleCoords->[$i][0]});
      }
    }
    
  }
  
  # Special case - if all the selectors were undef, then there
  # will be no dimension arrays on the result list.  Create
  # a single list that contains all the indices
  if (scalar(@res) == 0) {
    my @allIndices = (0..$lastIdx);
    push(@res, \@allIndices);
  }
  
  return \@res;

}                 

sub _getValueWalkingBackwards {
  my ($self, $dimArrays, $numPermutations) = @_;
  my $sum = 0;
  my $nDims = scalar(@{$dimArrays});
  my $dimBound = $nDims-1;
  my %blackList;
  my $permsFound = 0;

  my @idxs;
  for my $i (0 .. $dimBound) {
    $idxs[$i] = scalar(@{$dimArrays->[$i]})-1;
  }

  my $currMin = scalar(@{$self->{counts}});
 mainLoop:
  while ($permsFound < $numPermutations) {
    my $allTheSame = 1;
    foreach my $i (0 .. $dimBound) {
      while ($idxs[$i] >= 0 && $dimArrays->[$i][$idxs[$i]] > $currMin) {
        $idxs[$i]--;
      }
      if ($idxs[$i] < 0) {
        last mainLoop;
      }
      if ($dimArrays->[$i][$idxs[$i]] < $currMin) {
        $currMin = $dimArrays->[$i][$idxs[$i]];
        $allTheSame = 0 unless $i == 0;
      }
    }

    if ($allTheSame) {
      if ($blackList{$currMin}) {
      }
      else {
        $sum += $self->{counts}[$currMin][1];
        $permsFound++;
      }
      $blackList{$self->{counts}[$currMin][2]} = 1 if defined $self->{counts}[$currMin][2];
      $idxs[0]--;
      if ($idxs[0] < 0) {
        last mainLoop;
      }
    }

  }

  return $sum;

}


sub _getListWalkingForwards {
  my ($self, $dimArrays, $period, $start, $end) = @_;
  my $currSum = 0;
  my $nDims = scalar(@{$dimArrays});
  my $dimBound = $nDims-1;
  my @res;

  my @idxs;
  my @maxIdx;
  for my $i (0 .. $dimBound) {
    $idxs[$i] = 0;
    $maxIdx[$i] = scalar(@{$dimArrays->[$i]});
  }

  my $currMax = -1;

  my $lastSum;
  my $lastTime;
 mainLoop:
  while (1) {
    my $allTheSame = 1;
    foreach my $i (0 .. $dimBound) {
      while ($idxs[$i] < $maxIdx[$i] && 
             $dimArrays->[$i][$idxs[$i]] < $currMax) {
        $idxs[$i]++;
      }
      if ($idxs[$i] >= $maxIdx[$i]) {
        last mainLoop;
      }
      if ($dimArrays->[$i][$idxs[$i]] > $currMax) {
        $currMax = $dimArrays->[$i][$idxs[$i]];
        $allTheSame = 0 unless $i == 0;
      }
    }

    if ($allTheSame) {
      last mainLoop if defined($end) && $self->{counts}[$currMax][0] > $end;
      $currSum -= $self->{counts}[$self->{counts}[$currMax][2]][1] if defined $self->{counts}[$currMax][2];
      $currSum += $self->{counts}[$currMax][1];
      _addToPeriodicList(\@res, $period, $self->{counts}[$currMax][0], $currSum);
    }

    $idxs[0]++;
    if ($idxs[0] >= $maxIdx[0]) {
      last mainLoop;
    }
  }

  return \@res;

}

# Add the results to a list, taking into account
# duplicates for the same time as well as the periodic
# requirements
sub _addToPeriodicList {
  my ($list, $period, $time, $value) = @_;

  my $adjustedTime;
  if ($period) {
    $adjustedTime = (int($time/$period)+1)*$period;
  }
  else {
    $adjustedTime = $time;
  }

  my $lastIdx = scalar(@{$list})-1;
  
  if ($lastIdx >= 0) {
    if ($list->[$lastIdx][1] == $value) {
      return;
    }
    elsif ($lastIdx >= 0 && $list->[$lastIdx][0] == $adjustedTime) {
      # The penultimate entry on the list may already have this value
      # don't put it on if it is the same
      if ($lastIdx >= 1 && $list->[$lastIdx-1][1] == $value) {
        pop(@{$list});
      }
      else {
        $list->[$lastIdx] = [$adjustedTime, $value];
      }
      return;
    }
  }

  $list->[$lastIdx+1] = [$adjustedTime, $value];

}


# Returns the index of the last value that is equal to the search
# value or the first value that is greater.
sub _binarySearch {
  my ($list, $value) = @_;

  my $start        = 0;
  my $end          = scalar(@{$list}) - 1;
  my $origEnd      = $end;
  my $notDone      = 1;
  my $lastSmaller;
  my $lastEqual;
  
  while ($notDone) {

    if ($start >= $end) {
      $notDone = 0;
    }
    my $idx = int(($end-$start)/2)+$start;

    if ($list->[$idx] < $value) {
      $lastSmaller  = $idx;
      $start        = $idx+1;
    }
    elsif ($list->[$idx] == $value) {
      $start        = $idx+1;
      $lastEqual    = $idx;
    }
    else {
      $end          = $idx;
    }

  }

  return $lastEqual if defined $lastEqual;
  return $lastSmaller if defined $lastSmaller;
  return $origEnd;
}


1;
__END__

=head1 NAME

Data::RunningTotal - Module that allow you to keep track of running totals within a
multi-dimensional space.  Allows the access of the total at a point or volume at
any specified time.

=head1 SYNOPSIS

  use Data::RunningTotal;

  # Create a running total across 3 dimensions: owner, priority and product
  my $rt = Data::RunningTotal->new(dimensions => ["owner", "priority", "product"]);

  ## Simple interface
  my $time = 1;

  # increment the specified point by weight
  $rt->inc($time++, 
           weight => $weight, 
           coords => ["bob", "P1", "infinite improbablity generator"]);

  # decrement the specified point by weight
  $rt->dec($time++, 
           weight => $weight, 
           coords => ["sam", "P2", "genuine people personalities"]);

  ## Item based interface

  # Create a new event
  my $item = $rt->newItem(weight => $weight);

  # Shuffle this item around within the specified coordinates
  $item->moveTo($time++, coords => ["bob", "P1", "infinite improbability generator"]);
  $item->moveTo($time++, coords => ["sam", "P1", "infinite improbability generator"]);
  $item->moveTo($time++, coords => ["sam", "P2", "infinite improbability generator"]);
    
  # Get the number of bugs for "sam", "P1", "infinite improbability generator"
  # at time 4
  my $count = $rt->getValue(4, 
                            coords => ["sam", 
                                       "P2", 
                                       "infinite improbability generator"]);

  # Get the number of bugs for "sam" at time 10 (undef is a wildcard)
  $count = $rt->getValue(10, coords => ["sam", undef, undef]);

  # Get the list of count changes over time for priorities 1 and 2, between
  # time 0 and 100, inclusive, but only on 10 time-unit intervals
  my $list = $rt->getChangeList(start => 0,
                                end   => 100,
                                period => 10,
                                coords => [undef, sub {$_[0] =~ /^P[12]$/}, undef]);

  # Get all P3 and P4 priorities across all time at max granularity
  my $list2 = $rt->getChangeList(coords => [undef, sub {$_[0] =~ /^P[34]$/}, undef]);

  # Put the two preceding lists into a single list - note that they
  # don't need to have the same time contraints
  my $comblist = $rt->getChangeList($list, $list2);


=head1 DESCRIPTION

This module is used to make it easy to get a running total of items 
within a multi-dimensional space.  It was originally written to keep track of 
counts of open bugs across users, products and a bunch of other attributes so that 
it was possible to extract historical information from a bug database to
produce graphs of open bugs for various attributes over time.  While that was its
original purpose, it is completely generic and can be used for lots of other
purposes. 

The typical way of doing this is to create a new item for each thing being counted
(in my example, this is a bug) and then just move it around in the multi-dimensional
space using the 'moveTo' method.  When an item is created, the weight 
of that item can be specified or it defaults to 1.  This weight will be added to 
the point the item is moved to in the multi-dimensional space and subtracted from the 
point that it left.

After all the data has been stored in the RunningTotal db, the data can be
walked over for a specified volume (or point) or query a specific time for a specified
volume (or point).  For example, daily counts for priority 1 bugs of a period of a few
months can be extracted in order to generate a bug graph.

The following statement would get a list of changes to the volume that 
contains all bugs owned by all users, with priority P2 for all products.
If it wasn't clear, undef means all values in that dimension.

C< my @levelChanges = $rt-E<gt>getChangeList(coords = > [undef, "P2", undef]); >

Each entry in the returned list is an array ref that contains
[time, value], with the time being the time that the total of all items
in that volume changed and value being the new sum of all weights of those
items.    


=head1 Methods

=head2 new

new(%options)

Create at new running total with the specified dimensions.  Returns
a RunningTotal object reference.

The list of options are:

=over 12

=item dimensions (required)

A list of dimension names for the multi-dimensional space.  For example, if you were
counting within normal 3-d space, you might specify:  C< dimensions =E<gt> ['x', 'y', 'z'] >

=back 

=head2 inc

C<$rt-E<gt>inc($time, %options);>

Increment the point specified by I<coords> by value I<weight>.  Weight
defaults to 1 if not specified.

The list of options are:

=over 12

=item coords

Required parameter specifying the location that is being incremented.

C< coords =E<gt> ["loc1", "loc2", ...] >

=item weight

Optional parameter to specify the value of the increment

C< weight =E<gt> <weightE<gt> >

=back

=head2 dec

C< $rt-E<gt>dec($time, %options);>

Same as inc, except that the value is decremented at the specified
point and time.

=head2 getValue

C< my $value = $rt-E<gt>getValue($time, %options); >

Get a list of all changes over a range of time for the specified point or
volume.  

The method will return a list of array refs, with each containing
a time and value pair ([$time, $value]).

The options may be:

=over 12

=item coords

Required parameter specifying an array ref pointing to a list
of coordinate selectors.  Each item my be an exact coordinate, 
undef (for all coords in this dimension) or an anonymous sub
that will be called within each possible coordidate in that
dimension.

=back

=head2 getChangeList

C< my @changes = $rt-E<gt>getChangeList(%options); >

Get a list of all changes over a range of time for the specified point or
volume.  

The method will return a list of array refs, with each containing
a time and value pair ([$time, $value]).

The options may be:

=over 12

=item coords

Required parameter specifying an array ref pointing to a list
of coordinate selectors.  Each item my be an exact coordinate, 
undef (for all coords in this dimension) or an anonymous sub
that will be called within each possible coordidate in that
dimension.

C< coords =E<gt> [E<gt>coord|undef|sub{...}E<lt>, ...] >

=item start

Specifies the starting time for the list.  If not specified
the list will start with the earliest relevent event.

=item end 

Specifies the ending time for the list.  If not specified
the list will continue to the last relevent event.

=item period

Specifies a time interval for how often changed values should be returned.
For example, if you enter events using seconds, you could set period to 3600*24
to get a value for each day.

=back


=head2 combineChangeList

C< my $combList = $rt-E<gt>combineChangeList($list1, $list2, ...);>

This method takes a many lists in the form that are returned from 
getChangeList and merges them into a single list.  That single list
will have an entry for each distinct time from all the specified lists.
The entry will have the form: C<[time, list1Val, list2Val, ...]>.

A convenient was to use it is (using the bug example again):

   my $combList = 
     $rt->combineChangeList(
       $rt->getChangeList(undef, "P1", undef),
       $rt->getChangeList(undef, "P2", undef),
       $rt->getChangeList(undef, "P3", undef),
       $rt->getChangeList(undef, "P4", undef),
       $rt->getChangeList(undef, "P5", undef));

The preceding example would give a single list in which each entry
has a count for a different priority.


=head2 newItem

C< $item = $rt-E<gt>newItem(%options) >

Create a new item that will be moved within the multi-dimensional space.  
The weight will be used when adding to the new point it is moved to
and subtracting from the point it is leaving.

Options:

=over 12

=item weight

Optional parameter to specify the weight of an item.  If not specified,
it defaults to 1.

=back

=head2 moveTo

$item-E<gt>moveTo($time, %options);

Subtract the item's weight from its current location and move it
to the specified new point, where its weight will be added.

A MAJOR limitation of this command is that movements must occur in 
ascending time order.  In other words, you can't move to a point in 
the past.

Options:

=over 12

=item coords

Required parameter to specify the coordidates to move to

C< coords =E<gt> ["loc1", "loc2", ...] >

=back

=head1 SEE ALSO


=head1 AUTHOR

Edward Funnekotter, E<lt>efunneko+cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Edward Funnekotter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
