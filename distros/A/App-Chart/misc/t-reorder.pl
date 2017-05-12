#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Data::Dumper;

use constant DEBUG => 0;

sub make_perms {
  my @items = @_;
  if (@items == 0) { return (); }
  if (@items == 1) { return [ $items[0] ]; }
  my @perms;
  foreach my $i (0 .. $#items) {
    my $first = $items[$i];
    my @rest = @items;
    splice @rest, $i,1;
    my @subperms = make_perms (@rest);
    push @perms, map {[$first,@$_ ]} @subperms;
  }
  return @perms;
}

my $end = 7;
my @perms = make_perms (0 .. $end);
# print Dumper (\@perms);

sub move {
  my ($wref, $item, $pos) = @_;
  if (DEBUG) { print "move [",$item->[0],"] to $pos\n"; }
  @$wref = grep {$_ != $item} @$wref;
  splice @$wref, $pos,0, $item;
}

sub reorder_by_move_item {
  my ($aref, $move) = @_;

  my $offset = 0;
  foreach my $newpos (0 .. $#$aref) {
    my $oldpos = $aref->[$newpos];
    if ($newpos != $oldpos + $offset) {
      $move->($newpos, $oldpos);
      $offset -= ($newpos <=> $oldpos+$offset);
    }
  }
}

sub reorder_array_prune_shuffles {
  my ($aref) = @_;
  my $offset = 0;
  foreach my $newpos (0 .. $#$aref) {
    my $oldpos = $aref->[$newpos];
    if ($newpos == $oldpos + $offset) {
      $aref->[$newpos] = undef;
    } else {
      $offset -= ($newpos <=> $oldpos+$offset);
    }
  }
}

sub make_reorder_move_test {
  my $offset = 0;
  return sub {
    my ($newpos, $oldpos) = @_;
    my $cmp = ($oldpos+$offset <=> $newpos);
    $offset += $cmp;
    return $cmp;
  }
}

sub reorder {
  my ($aref) = @_;
  if (DEBUG) { print "\n"; }

  my @widget = map {[$_+10]} 0 .. $#$aref;
  my @children = ( @widget );

  if (1) {
    my $want_move = make_reorder_move_test();
    foreach my $newpos (0 .. $#$aref) {
      my $oldpos = $aref->[$newpos];
      if ($want_move->($newpos,$oldpos)) {
        my $item = $children[$oldpos];
        move (\@widget, $item, $newpos);
      }
    }

  } elsif (1) {
    my @acopy = @$aref;
    my $aref = \@acopy;
    reorder_array_prune_shuffles ($aref);

    foreach my $newpos (0 .. $#$aref) {
      my $oldpos = $aref->[$newpos];
      if (defined $oldpos) {
        my $item = $children[$oldpos];
        move (\@widget, $item, $newpos);
      }
    }

  } elsif (0) {
    reorder_by_move_item ($aref, sub { my ($newpos, $oldpos) = @_;
                                       my $item = $children[$oldpos];
                                       move (\@widget, $item, $newpos);
                                     });
  } else {
    my $offset = 0;
    foreach my $newpos (0 .. $#$aref) {
      my $oldpos = $aref->[$newpos];
      if ($newpos != $oldpos + $offset) {
        my $item = $children[$oldpos];
        move (\@widget, $item, $newpos);
        $offset -= ($newpos <=> $oldpos+$offset);
      }

      if (DEBUG) { print "  ",join(' ', map {$_->[0]} @widget),
                     "   newpos $newpos offset $offset\n"; }
    }
  }

  #   print Dumper ($aref);
  #   print Dumper (\@widget);
  if (DEBUG)  {
    print join(' ',@$aref), ' -> ', join(' ',map{$_->[0]}@widget), "\n";
  }

  foreach my $i (0 .. $#$aref) {
    my $got = $widget[$i]->[0] - 10;
    my $want = $aref->[$i];
    if ($got != $want) {
      print "  wrong at $i (got $got, want $want)\n";
      print Dumper($aref);
      print Dumper(\@widget);
      exit 0;
    }
  }
}

# [-1..-1]
foreach my $perm (@perms) {
  reorder ($perm);
}

exit 0;



#------------------------------------------------------------------------------
# reorder helper
#
# make_reorder_test() returns a code ref procedure to test whether
# successive entries in a TreeModel style reorder array need to be applied.
#
# The procedure should be called $test->($newpos,$oldpos) on newpos values 0
# to N successively, with oldpos the position before any reordering.  It
# returns true if a move should be applied.  Eg.
#
#     $test = make_reorder_test();
#     foreach my $newpos (0 .. $#$reorder_array) {
#       my $oldpos = $reorder_array->[$newpos];
#       if ($test->($newpos,$oldpos)) {
#         my $item = $original_items[$oldpos];
#         move ($item, $newpos);
#       }
#     }
#
# The move is expected to be in the style of Gtk2::Menu::reorder_child(),
# shifting items at and beyond $newpos upwards.
#
# Basically $test keeps track of how much items at and beyond newpos have
# been moved up due to that shifting.  If an item is in its correct position
# due to that shifting then there's no need for a move() call.
#
# This move call suppression is geared towards Gtk2::Menu::reorder_child()
# because as of Gtk 2.12 that function doesn't notice when a reorder request
# is asking for an unchanged position, it does some linear time linked-list
# searches anyway, and looping that over 0 to N ends up as O(N^2) time.  A
# loop over 0 to N is not optimal, but it's simple, and in particular the
# supression test 


sub make_reorder_test {
  my $offset = 0;
  return sub {
    my ($newpos, $oldpos) = @_;
    my $cmp = ($oldpos+$offset <=> $newpos);
    $offset += $cmp;
    return $cmp;
  }
}



  # When visible, shuffle around according to reorder array.
  # For a big lot of moves maybe a re-setup would be better, though for a
  # small shuffle in the list a $menu->reorder_child should be best.
  #
  my ($tearoff, @children) = _tearoff_and_children ($self);
  if (@children < @$aref) {
    carp __PACKAGE__.': oops, reorder array bigger than num children ('
      . scalar(@$aref) . ',' . scalar(@children) . ')';
    _recover_after_inconsistency ($self);
    return;
  }

  my $test = make_reorder_test();
  foreach my $newpos (0 .. $#$aref) {
    my $oldpos = $aref->[$newpos];
    if ($test->($newpos,$oldpos)) {
      my $item = $children[$oldpos];
      if ($item) {
        $self->reorder_child ($item, $newpos + $tearoff);
      } else {
        carp __PACKAGE__.": oops, reorder array bad oldpos $oldpos";
        _recover_after_inconsistency ($self);
        return;
      }
    }
  }
