package Class::DBI::Plugin::Calendar::Day;
use strict;
use warnings FATAL => 'all';

use Carp;

our $VERSION = '0.02';

use constant DATE => 0;
use constant AREF => 1;

sub new {
	my($class,$date,$aref) = @_;
	
	my @array = ();
	$array[DATE] = $date;
	$array[AREF] = $aref;
	return bless \@array, $class;
}

#
# is this a valid date, or a placeholder?
#
sub ok {
	my $self = shift;
	return ref $self->[DATE] ? 1 : 0;
}
*is = *is_good = *good = *is_ok = *ok; # aliases

#
# what's the date for this day?
#
sub date {
	my $self = shift;
	
	croak "Cannot call a Class::DBI::Plugin::Calendar::Day object that's !$self->ok"
		unless $self->ok;
	
	$self->[DATE];
}

#
# does the date hold any events?
# how many?
#
sub has  { scalar @{shift->[AREF]} }
*num_events = *num = *sum = *has; # all tell if/how many events are in that day
sub empty { !shift->has }

#
# what are the events? aref or array
#
sub agenda { wantarray ? @{shift->[AREF]} : shift->[AREF] }
*events = *objects = *agenda;

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::DBI::Plugin::Calendar::Day - Calendar Day Support for Class::DBI

=head1 SYNOPSIS

  package DB;
  use base 'Class::DBI';
  use Class::DBI::Plugin::Calendar qw(date_fieldname);

  my @weeks = DB->calendar; # current month, based on Calendar::Simple
  for my $week (@weeks) {
    for my $day (@$week) { # always 7 days, some may be placeholders
      if($day->ok) {
        printf '%03d', $day->date->mday;
      } else { # just a placeholder
        print "   ";
      }
      print "\n";
    }
  }
  
  @events = $day->events unless $day->empty;

=head1 DESCRIPTION

These are simple objects which represent days in Class::DBI::Plugin::Calendar
applications.

=head2 my $real = $day->ok

This means that this day refers to a real day, and is not just a placeholder
so that the week in which it resides may contain seven days. This should be
called before $day->date for each object. Otherwise, you're in danger of
croak()ing. Aliases are: is, good, is_good, is_ok.

=head2 my $time_piece = $day->date

This returns a Time::Piece object representing the date. You must call $day->ok
before this method, since the application will croak() if this day does not
represent a valid date. (It may be a simple placeholder so that weeks always
have seven days, in order.

=head2 my $num = $day->num_events

This gives the number of events in the day. Aliases: num, sum, has.

=head2 my $has_none = $day->empty

The opposite of num_events.

=head2 my @events = $day->agenda

The events for that day, ordered by date_fieldname (above). Aliases:
objects, events

=head1 SEE ALSO

Class::DBI, Calendar::Simple, Class::DBI::Plugin::Calendar

=head1 AUTHOR

James Tolley, E<lt>james@bitperfect.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
