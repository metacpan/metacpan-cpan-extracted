package DateTime::Schedule::Weekly 0.03;
use v5.26;

# ABSTRACT: Augment DateTime::Schedule with a weekly recurrrence pattern

use Object::Pad;

class DateTime::Schedule::Weekly {
  inherit DateTime::Schedule;

  use Readonly;
  Readonly::Array my @DAY_NUMS => (undef, qw(monday tuesday wednesday thursday friday saturday sunday));

  use constant true  => !!1;
  use constant false => !true;

  field $sunday : param : reader    = true;
  field $monday : param : reader    = true;
  field $tuesday : param : reader   = true;
  field $wednesday : param : reader = true;
  field $thursday : param : reader  = true;
  field $friday : param : reader    = true;
  field $saturday : param : reader  = true;

  field $include : param : reader = [];

  ADJUST {
    die("At least one day must be scheduled")
      unless ($self->sunday
      || $self->monday
      || $self->tuesday
      || $self->wednesday
      || $self->thursday
      || $self->friday
      || $self->saturday);

    $include = {map {$_->strftime('%F') => true} ($include // [])->@*};
  }

  sub weekdays($class, @params) {
    __PACKAGE__->new(sunday => false, saturday => false, @params);
  }

  sub weekends($class, @params) {
    __PACKAGE__->new(monday => false, tuesday => false, wednesday => false, thursday => false, friday => false, @params);
  }

  method is_day_scheduled($d) {
    my $day_name = $DAY_NUMS[$d->day_of_week];
    my $str      = $d->strftime('%F');
    return false if ($self->exclude->{$str});
    return $self->include->{$str} || $self->$day_name;
  }
}

=head1 NAME

DateTime::Schedule::Weekly - Determine scheduled days in range based on weekly recurrence and inclusions/exclusions

=head1 SYNOPSIS

  use DateTime::Schedule::Weekly;

  my $dts = DateTime::Schedule::Weekly->weekdays(exclude => [...list of school holidays...], portion => 0.5);

  my $school_days_elapsed = $dts->days_in_range($first_day_of_school, $now)->count;

=head1 DESCRIPTION

This subclass of L<DateTime::Schedule> augments its capabilities to support a 
regular weekly schedule of on/off days.

=head1 CONSTRUCTORS

=head2 new

Returns a new instance. Permits the following construction parameters, in 
addition to those supported by L<DateTime::Schedule>:

=head4 sunday, monday, tuesday, wednesday, thursday, friday, saturday

I<Optional>. Default C<true>

These seven constructor parameters indicate which days of the week are "scheduled"
By default, all are "on", making the behavior identical to L<DateTime::Schedule>'s.

=head4 include

I<Optional>. Default C<[]>

An arrayref of L<DateTime>s. These days are included over and above the normal
schedule.

E.g., a school schedule could be regularly M-F, but due to extensive weather-related
closures, the school added in one or more saturdays class days. These would be
C<include>d.

B<N.B. Exclusions have priority over inclusions, so a date in both lists will be excluded!>

=head2 weekdays

Identical to calling L</new> except that by default C<saturday> and C<sunday> are
"off".

=head2 weekends

Identical to calling L</new> except that by default C<monday>, C<tuesday>, 
C<wednesday>, C<thursday>, and C<friday> are "off".

=head1 METHODS

Implements all methods from L<DateTime::Schedule>

=head2 is_day_scheduled($datetime)

Given a L<DateTime>, returns false if date is in the exclusion list. Otherwise
returns true if date is in the inclusion list or if date is in a scheduled day
of week. Returns false otherwise.

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__

