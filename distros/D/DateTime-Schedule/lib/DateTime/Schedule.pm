package DateTime::Schedule 0.03;
use v5.26;

# ABSTRACT: Determine scheduled days in range based on inclusions/exclusions

use Object::Pad;

class DateTime::Schedule {
  use DateTime::Set;

  field $portion : param : reader = 1;


  field $exclude : param : reader = [];

  ADJUST {
    $portion = 0 if ($portion < 0);
    $portion = 1 if ($portion > 1);

    $exclude = {map {$_->strftime('%F') => 1} ($exclude // [])->@*};
  }

  method day_frac($datetime) {
    my $this_day = $datetime->clone->truncate(to => 'day');
    my $next_day = $this_day->clone->add(days => 1);
    my $total    = $next_day->epoch - $this_day->epoch;       #total number of seconds in "this" day
    my $diff     = $datetime->epoch - $this_day->epoch;       #number of seconds elapsed since beginning of day
    return $diff / $total;
  }

  method is_day_scheduled($d) {
    my $str = $d->strftime('%F');
    return !$self->exclude->{$str};
  }

  method days_in_range($start, $end) {
    $start = $start->clone;
    $end   = $end->clone;
    $end   = $end->add(days => 1) if ($self->day_frac($end) > $self->portion);
    $start->truncate(to => 'day');
    $end->truncate(to => 'day');

    my $dates = [];
    my $d     = $start->clone;
    while ($d < $end) {
      push($dates->@*, $d->clone) if ($self->is_day_scheduled($d));
      $d->add(days => 1);
    }
    DateTime::Set->from_datetimes(dates => $dates);
  }

}

=head1 NAME

DateTime::Schedule - Determine scheduled days in range based on exclusions

=head1 SYNOPSIS

  use DateTime::Schedule;

  my $dts = DateTime::Schedule->new(exclude => [
    DateTime->new(year => 2024, month => 01, day => 01),
    DateTime->new(year => 2024, month => 07, day => 04),
    DateTime->new(year => 2024, month => 12, day => 25)
  ]);

  my $start = DateTime->new(year => 2024, month => 1, day => 1);
  my $end = DateTime->new(year => 2024, month => 12, day => 31);
  print $dts->days_in_range($start, $end)->count; # 363

=head1 DESCRIPTION

This is a simple class that allows you to find out which days are "scheduled"
between a start date and an end date. For instance, given the start date of a
school year, and the current date, and with all school holidays entered as 
L</exclude>d, this can tell you how many school days have elapsed in the year.

=head1 CONSTRUCTORS

=head2 new

Default constructor. Returns a new L<DateTime::Schedule> instance.

Parameters:

=head4 portion

I<Optional>. Default C<1>.

A number between 0 and 1 indicating how much of a day must elapse to be
included/excluded at the boundaries of the range.

=head4 exclude

I<Optional>. Default C<[]>

An arrayref of L<DateTime>s. These days are exclusions to the normal schedule
(e.g., holidays). Any time-portion of the DateTimes is ignored.

=head1 METHODS

=head2 is_day_scheduled($datetime)

Given a L<DateTime>, returns true/false to indicate whether that day is 
scheduled or not. 

Should be overridden by subclasses.

=head2 days_in_range($start, $end)

Given start/end L<DateTime>s, returns a L<DateTime::Set> of all the days which
are scheduled (i.e., not excluded)

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
