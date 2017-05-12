package Date::Range;

=head1 NAME

Date::Range - work with a range of dates

=head1 SYNOPSIS

  use Date::Range;

  my $range = Date::Range->new($date1, $date2);

  my $earliest = $range->start;
  my $latest   = $range->end;
  my $days     = $range->length;

  if ($range->includes($date3)) { ... }
  if ($range->includes($range2)) { ... }

  if ($range->overlaps($range2)) {
    my $range3 = $range->overlap($range2);
  }

  foreach my $date ($range->dates) { ... }

=head1 DESCRIPTION

Quite often, when dealing with dates, we don't just want to know
information about one particular date, but about a range of dates. For
example, we may wish to know whether a given date is in a particular
range, or what the overlap is between one range and another.  This module
lets you ask such questions.

=cut

$VERSION = '1.41';

use strict;
use Carp;


=head1 METHODS

=head2 new()

  my $range = Date::Range->new($date1, $date2);

A range object is instantiated with two dates, which do not need
to be in chronological order (we'll sort all that out internally).

These dates must be instances of the correct object. See want_class()
below.

=head2 want_class

The class of which we expect the date objects to be objects. By default
this is L<Date::Simple>, but this could be any other date class. See
L<Time::Piece::Range> for an example of a subclass that uses a different
date class.

=cut

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my @dates = sort { $a <=> $b } grep UNIVERSAL::isa($_ => $class->want_class), @_;
  croak "You must create a range from two date objects" unless (@dates == 2);
  my $self = bless {
    _start => $dates[0],
    _end   => $dates[1],
  }, $class;
  return $self;
}

sub want_class { 'Date::Simple' }

=head2 start / end / length

  my $earliest = $range->start;
  my $latest   = $range->end;
  my $days     = $range->length;

These methods allow you retrieve the start and end dates of the range,
and the number of days in the range. 

=cut

sub start  { $_[0]->{_start} }
sub end    { $_[0]->{_end}   }
sub length { (int ($_[0]->end - $_[0]->start) / $_[0]->_day_length)  +1 }

sub _day_length { 1 }

=head2 equals

  if ($range1->equals($range2)) { }

This tells you if two ranges are the same - i.e. start and end at
the same dates. 

=cut

sub equals {
  my ($self, $check) = @_;
  return unless UNIVERSAL::isa($check => 'Date::Range');
  return ($self->start == $check->start and $self->end == $check->end);
}

=head2 includes

  if ($range->includes($date3)) { ... }
  if ($range->includes($range2)) { ... }

These methods tell you if a given range includes a given date, 
or a given range.

=cut

sub includes {
  my ($self, $check) = @_;
  if (UNIVERSAL::isa($check => 'Date::Range')) {
    return $self->includes($check->start) && $self->includes($check->end);
  } elsif ($check->isa($self->want_class)) {
    return $self->start <= $check && $check <= $self->end;
  } else {
    croak "Ranges can only include dates or ranges";
  }
}

=head2 overlaps / overlap

  if ($range->overlaps($range2)) {
    my $range3 = $range->overlap($range2);
  }

These methods let you know whether one range overlaps another or not,
and access this overlap range.

=cut

sub overlaps { 
  my ($self, $check) = @_;
  return unless UNIVERSAL::isa($check => 'Date::Range');
  return $check->includes($self->start) || $check->includes($self->end) 
      || $self->includes($check);
}

sub overlap { 
  my ($self, $check) = @_;
  return unless UNIVERSAL::isa($check => 'Date::Range');
  return unless $self->overlaps($check);
  my @dates = sort { $a <=> $b } $self->start, $self->end, 
                                 $check->start, $check->end;
  return $self->new(@dates[1..2]);
}

=head2 gap

	my $range3 = $range->gap($range2);

This returns a new range representing the gap between two other ranges.

=cut

sub gap {
	my ($self, $range) = @_;
	return if $self->overlaps($range);
  my @sorted = sort { $a->start <=> $b->start } ($self, $range);
	my $start = $sorted[0]->end + $self->_day_length;
	my $end = $sorted[1]->start - $self->_day_length;
	return if $start >= $end;
	return $self->new($start, $end);
}

=head2 abuts

	if ($range->abuts($range2)) { ... }

This tells you whether or not two ranges are contiguous - i.e. there is
no gap between them, but they do not overlap.

=cut

sub abuts { 
	my ($self, $range) = @_;
	return ! ($self->overlaps($range) || $self->gap($range));
}

=head2 dates

  foreach my $date ($range->dates) { ... }

This returns a list of each date in the range as a Date::Simple object.

=cut

sub dates {
  my $self = shift;
  my @dates;
  my $start = $self->start;
  for (1..$self->length) {
      push @dates, $start;
      $start += $self->_day_length;
  }
  return @dates;
}

1;

=head1 AUTHOR

Tony Bowden, based heavily on Martin Fowler's "Analysis Patterns 2"
discussion and code at http://www.martinfowler.com/ap2/range.html

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Date-Range@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2006 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


