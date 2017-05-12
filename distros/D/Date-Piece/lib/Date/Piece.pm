package Date::Piece;
$VERSION = v0.0.3;

use warnings;
use strict;
use Carp;

use Time::Piece;
{
  no warnings 'redefine';
  *Time::Piece::ymd = *Time::Piece::date = sub {
    my $t = shift;
    return Date::Piece->new($t->year, $t->mon, $t->mday);
  };
}

use base 'Date::Simple';

=head1 NAME

Date::Piece - efficient dates with Time::Piece interoperability

=head1 SYNOPSIS

  use Date::Piece qw(date);

  my $date = date('2007-11-22');
  my $time = $date->at('16:42:35');

  print $time, "\n"; # is a Time::Piece

You can also start from a Time::Piece object.

  use Time::Piece;
  use Date::Piece;

  my $time = localtime;
  my $date = $time->date; # also ymd()

  $date+=7;
  # seven days later
  print $date, "\n";

  # seven days later at the original time
  print $date->at($time), "\n";

=head1 ABOUT

This module allows you to do I<nominal> math on dates.  That is, rather
than worrying about time zones and DST while adding increments of
24*60**2 seconds to a date&time object, you simply discard the time
component and do math directly on the date.  If you need a time-of-day
on the calculated date, the at() method returns a Time::Piece object,
thus allowing you to be specific about the endpoints of a nominal
interval.

This is useful for constructs such as "tomorrow", "yesterday", "this
time tomorrow", "one week from today", "one month later", "my 31st
birthday", and various other not-necessarily-numeric intervals on the
arbitrary and edge-case-laden division of time known by most earthlings
as "the calendar."  That is, adding days or months is analogous to
counting squares or turning pages on a calendar.

This module extends Date::Simple and connects it to Time::Piece.  See
Date::Simple for more details.

=head1 Immutable

A Date::Piece object never changes.  This means that methods like add_months() always return a new object.

This does not I<appear> to be true with constructs such as C<$date++> or
C<$date+=7>, but what is actually happening is that perl treats the
variable as an lvalue and assigns the new object to it.  Thus, the
following is true:

  my $also_date = my $date = today;
  $date++;
  $date > $also_date;

=head1 Validation

Where Date::Simple returns false for invalid dates, I throw errors.

=head1 Convenient Syntax

You may import the functions 'date' and 'today' as well as the
unit-qualifiers 'years', 'months', and 'weeks'.

When loaded as -MDate::Piece with perl -e (and/or -E in 5.10), these
extremely short versions are exported by default:

  years  => 'Y',
  months => 'M',
  weeks  => 'W',
  date   => 'D',
  today  => 'CD', # mnemonic: Current Date

You may unimport any imported functions with the 'no Date::Piece'
directive.

=cut

=head1 Functions

=head2 today

This returns the current date.  Don't be afraid to use it in arithmetic.

  my $today = today;
  my $tomorrow = today + 1;

=head2 date

  my $new_year_is_coming = date('2007-12-31');

Equivalent to Date::Piece->new('2007-12-31');

Also takes year, month, day arguments.

  my $d = date($year, $month, $day);

=cut

sub today () { __PACKAGE__->_today }
sub date { 
  my $d = __PACKAGE__->_new(@_);
  $d or croak("invalid date @_");
  return($d);
}

########################################################################
# I-hate-exporter overhead
my @export_ok = qw(
  today
  date
);
my $gensub = sub {
  my $part = shift;
  my $sub = eval("sub () { Date::Piece::${part}_unit->new(1) }");
  $@ and die "gah $@";
  return($sub);
};
my %export_as = (
  map({("${_}s" => $gensub->($_))} qw(year month week day)),
  centuries => $gensub->('century'),
);
my %exported;
my $do_export = sub {
  my $package = shift;
  my ($caller, $function, $as) = @_;
  $as ||= $function;

  my $track = $exported{$package} ||= {};
  $track = $track->{$caller} ||= {};

  $track->{$as} = $function;
  my $sref = $export_as{$function} ||
    $package->can($function) or croak("cannot $function");
  no strict 'refs';
  *{$caller . '::' . $as} = $sref;
};

sub import {
  my $package = shift;
  my (@args) = @_;

  my ($caller, $file, $line) = caller;

  if(not $line and lc($file) eq '-e') {
    $package->$do_export($caller, @$_) for(
      [years  => 'Y'],
      [months => 'M'],
      [weeks  => 'W'],
      [date   => 'D'],
      [today  => 'CD'],
    );
  }

  my %ok = map({$_ => 1} @export_ok, keys(%export_as));
  foreach my $arg (@args) {
    $ok{$arg} or croak("$arg is not exported by the $package module");
  }
  $package->$do_export($caller, $_) for(@args);
}

=head2 unimport

Clean-out the imported methods from your namespace.

  no Date::Piece;

=cut

sub unimport {
  my $package = shift;
  my $caller = caller;

  my $track = $exported{$package} ||= {};
  $track = $track->{$caller} ||= {};
  foreach my $func (keys(%$track)) {
    no strict 'refs';
    delete(${$caller . '::'}{$func});
  }
}
# end another-thing-to-be-modularized
########################################################################

=head2 new

Takes the same arguments as date().

=cut

sub new {
  my $package = shift;
  my $obj = $package->SUPER::new(@_) or croak("invalid date @_");
  return($obj);
}

=head1 Methods

TODO paste most of the Date::Simple documentation here?

=head2 Note: lack of complete API compatibility with Time::Piece

Ideally, we should have the Time::Piece API, but Date::Simple doesn't do
that.  I'm I<trying> to avoid a complete fork of Date::Simple, but will
likely need to do that just to make e.g. month() do the same thing that
it does in Time::Piece.  Ultimately, a Date::Piece should act exactly
like a Time::Piece where the time is always midnight (which implies that
adding seconds upgrades the result to a Time::Piece and etc.)


=head2 Y

  $date->Y;

=cut

sub Y {
  my $self = shift;
  $self->year;
} # end subroutine Y definition
########################################################################

=head2 M

  $date->M;

=cut

sub M {
  my $self = shift;
  $self->month;
} # end subroutine M definition
########################################################################

=head2 mon

  $date->mon;

=cut

sub mon {
  my $self = shift;
  $self->at('16:00')->monname;
} # end subroutine mon definition
########################################################################

=head2 monthname

  $date->monthname;

=cut

sub monthname {
  my $self = shift;
  $self->at('16:00')->fullmonth;
} # end subroutine monthname definition
########################################################################

=head2 D

  $date->D;

=cut

sub D {
  my $self = shift;
  $self->day;
} # end subroutine D definition
########################################################################

=head2 iso_dow

Returns the day of the week (0-6) with Monday = 0 (as per ISO 8601.)

  my $dow = $date->iso_dow;

See day_of_week() if you want Sunday as the first day (as in localtime.)

=cut

sub iso_dow {
  my $self = shift;
  my $dow = $self->day_of_week;
  $dow--;
  return($dow < 0 ? 6 : $dow);
} # end subroutine iso_dow definition
########################################################################

=head2 iso_wday

Returns 1-7 where Monday is 1.

  my $wday = $date->iso_wday;

=cut

sub iso_wday {
  my $self = shift;
  return($self->iso_dow+1);
} # end subroutine iso_wday definition
########################################################################

=head1 Setting the Time on a Date

=head2 at

Returns a Time::Piece object at the given time on the date C<$date>.

  my $timepiece = $date->at($time);

$time can be in 24-hour format (seconds optional) or have an 'am' or
'pm' (case insensitive) suffix.

$time may also be of the form '1268s', which will be taken as a number
of seconds to be added to midnight on the given day (and may be
negative.)

The time is constructed via Time::Local.  For concerns about daylight
savings, see the caveats in Time::Local.

If $time is a Time::Piece from a different time zone, we *should*
respect that, but currently do the wrong thing.

=cut

sub at {
  my $self = shift;
  my ($h, $m, $s) = @_;

  # XXX just throw it at Date::Parse?
  my $offset;
  unless(defined($m)) { # parse-out $h
    if(ref($h)) { # a time object
      ($h,$m,$s) = split(/:/, $h->hms);
    }
    elsif($h =~ s/s$//) { # number-of-seconds
      $offset = $h;
      ($h, $m, $s) = (0,0,0);
    }
    else {
      ($h, $m, $s) = $self->_parse_at($h);
    }
  }
  require Time::Local;

  # XXX doesn't respect UTC on an incoming Time::Piece

  my $time = Time::Piece->new(
    Time::Local::timelocal($s,$m,$h,
      $self->day, $self->month - 1, $self->year - 1900
    )
  );
  $time += $offset if($offset);
  return($time);
} # end subroutine at definition
########################################################################

sub _parse_at {
  my $self = shift;
  my ($t) = @_;

  my @bits = split(/:/, $t);
  (@bits > 3) and croak("invalid time $t");
  (@bits >= 2) or croak("invalid time $t");

  if($bits[-1] =~ s/([ap])m$//i) {
    my $d = lc($1);
    if($bits[0] == 12) {
      $bits[0] = 0 if($d eq 'a');
    }
    else {
      $bits[0] += 12 if($d eq 'p');
    }
  }

  $bits[2] ||= 0;

  return(@bits);
} # end subroutine _parse_at definition
########################################################################

# TODO next("wednesday"), last("wednesday") (also prev("wed"))

=head1 Endpoints

These are all very simple, but convenient.

=head2 start_of_year

January 1st of the year containing $date.

  my $start = $date->start_of_year;

=cut

sub start_of_year {
  my $self = shift;
  return($self->new($self->year, 1, 1));
} # end subroutine start_of_year definition
########################################################################

=head2 end_of_year

December 31st of the year containing $date.

  my $end = $date->end_of_year;

=cut

sub end_of_year {
  my $self = shift;
  return($self->new($self->year, 12, 31));
} # end subroutine end_of_year definition
########################################################################

=head2 start_of_month

Returns the 1st of the month containing $date.

  my $start = $date->start_of_month;

=cut

sub start_of_month {
  my $self = shift;
  return $self->new(($self->as_ymd)[0,1], 1);
} # end subroutine start_of_month definition
########################################################################

=head2 end_of_month

Returns the last day of the month containing $date.

  my $end = $date->end_of_month;

=cut

sub end_of_month {
  my $self = shift;
  return($self->new(($self->as_ymd)[0,1], $self->days_in_month));
} # end subroutine end_of_month definition
########################################################################

=head2 days_in_month

Returns the number of days in the month containing $date.

  my $num = $date->days_in_month;

See also C<Date::Simple::days_in_month($year, $month)>.

=cut

sub days_in_month {
  my $self = shift;
  return(Date::Simple::days_in_month(($self->as_ymd)[0,1]));
} # end subroutine days_in_month definition
########################################################################

=head2 leap_year

Returns true if Date is in a leap year.

  my $bool = $date->leap_year;

See also C<Date::Simple::leap_year($year)>.

=cut

sub leap_year {
  my $self = shift;
  return(Date::Simple::leap_year($self->year));
} # end subroutine leap_year definition
########################################################################

=head2 thru

Returns a list ala $start..$end (because overloading doesn't work with
the '..' construct.)  Will work forwards or backwards.

  my @list = $date->thru($other_date);

=cut

sub thru {
  my $self = shift;
  my $i = $self->iterator(@_);

  my @ans;
  while(my $d = $i->()) { push(@ans, $d); }
  return(@ans);
} # end subroutine thru definition
########################################################################

=head2 iterator

Returns a subref which iterates through the dates between $date and
$other_date (inclusive.)

  my $subref = $date->iterator($other_date);
  while(my $day = $subref->()) {
    # do something with $day
  }

=cut

sub iterator {
  my $self = shift;
  my ($other) = @_;
  ref($other) or $other = ref($self)->new($other);

  my $diff = $other - $self;
  my $abs_d = abs($diff);
  my $dir = $abs_d ? $diff/$abs_d : 1;
  my $count = 0;
  my $ref = sub {
    ($count++ > $abs_d) and return;
    my $now = $self; $self += $dir;
    return($now);
  };
} # end subroutine iterator definition
########################################################################

=head1 Fuzzy Math

We can do math with months and years as long as you're flexible about
the day of the month.  The theme here is to keep the answer within the
destination calendar month rather than adding e.g. 30 days.

=head2 adjust_day_of_month

Returns a valid date even if the given day is beyond the last day of the
month (returns the last day of that month.)

  $date = adjust_day_of_month($y, $m, $maybe_day);

=cut

sub adjust_day_of_month {
  my (@ymd) = @_;

  (@ymd == 3) or croak(
    "adjust_day_of_month() must have 3 arguments, not ", scalar(@ymd));

  if($ymd[2] > 28) { # optimize
    my $dim = Date::Simple::days_in_month(@ymd[0,1]);
    $ymd[2] = $dim if($ymd[2] > $dim);
  }
  
  return(@ymd);
} # end subroutine adjust_day_of_month definition
########################################################################

=head2 add_months

Adds $n I<nominal> months to $date.  This will just be a simple
increment of the months (rolling-over at 12) as long as the day part is
less than 28.  If the destination month doesn't have as many days as the
origin month, the answer will be the last day of the destination month
(via adjust_day_of_month().)

  my $shifted = $date->add_months($n);

Note that if $day > 28 this is not reversible.  One should not rely on
it for incrementing except in trivial cases where $day <= 28 (because
calling $date = $date->add_months(1) twice is not necessarily the same
result as $date = $date->add_months(2).)

=cut

sub add_months {
  my $self = shift;
  my ($months) = @_;

  return($self->add_years($months/12)) unless($months % 12);

  my @ymd = $self->as_ymd;

  # get raw month number, bound, and carry to years
  my $nm = $ymd[1]+$months;
  my $m  = $nm % 12 || 12;
  my $ya = ($nm - $m)/12;
  $ymd[0] += $ya;
  $ymd[1] = $m;
  return($self->new(adjust_day_of_month(@ymd)));
} # end subroutine add_months definition
########################################################################

=head2 add_years

Equivalent to adding $n*12 months.

  my $shifted = $date->add_years($n);

=cut

sub add_years {
  my $self = shift;
  my ($years) = @_;

  my (@ymd) = $self->as_ymd;

  $ymd[0]+= $years;

  # optimize: only check February
  @ymd = adjust_day_of_month(@ymd) if($ymd[1] == 2);

  return($self->new(@ymd));
} # end subroutine add_years definition
########################################################################

=head1 Year, Month, and etc "units"

The constants 'years', 'months', and 'weeks' may be multiplied by an
I<integer> and added to (or subtracted from) a date.

  use Date::Piece qw(today years);
  my $distant_future = today + 10*years;

  perl -MDate::Piece -e 'print CD+10*Y, "\n";'

The unit objects stringify as e.g. '10years'.

You may also divide time units by a number as long as the result is an
integer.  You may not use units as a divisor.

Any math done on these units which yields other than an integer will
throw a run-time error.

Also available are 'centuries' and 'days' (the latter is convenient as a
stricture to ensure that your days are integers.)

Conversion between these units only makes sense for centuries => years
and weeks => days, but is currently not available.

=cut

BEGIN {
  package Date::Piece::unit_base;

  use Carp;

  sub new {
    my $package = shift;
    my ($v) = @_;
    my $int = int($v);
    ($v == $int) or croak("can only work in integer ", $package->unit);
    $v = $int;
    my $class = ref($package) || $package;
    bless(\$v, $class);
  } # end subroutine new definition
  use overload (
    '*' => sub {shift->_redispatch('multiply', @_)},
    '/' => '_divide',
    '+' => sub {shift->_redispatch('add', @_)},
    '-' => sub {shift->_redispatch('subtract', @_)},
    '""' => sub { my $self = shift; $$self . $self->unit },
    #fallback => 1,
  );
  sub _redispatch {
    my ($self, $op, $and, $r) = @_;

    my $sref = ref($self);
    my $aref = ref($and);

    my $method = '_' . $op;

    # check sanity and maybe send elsewhere
    if($aref and $aref->isa('Date::Simple')) {
      $aref->can($method) or
        croak("cannot $op ", $self->unit, " with a date");
      return($and->$method($self, $r ? 0 : 1));
    }
    if($sref and $aref) {
      ($sref eq $aref) or croak("cannot $op dissimilar units");
    }

    return($self->$method($and, $r));
  }

  sub _add {
    my ($self, $and, $r) = @_;
    $self->new($$self + $and);
  }
  sub _subtract {
    my ($self, $op, $r) = @_;
    $self->new($r ? $op - $$self : $$self - $op);
  }
  sub _multiply {
    my ($self, $and, $r) = @_;
    $self->new($$self * $and);
  }
  sub _divide {
    my ($s, $v, $r) = @_;
    # TODO 1week/7 => 1day
    croak($s->unit, " cannot be in the denominator") if($r);
    $s->_redispatch('multiply', 1/$v, $r);
  }

  package Date::Piece::century_unit;
  our @ISA = qw(Date::Piece::unit_base);
  use constant unit => 'centuries';
  package Date::Piece::year_unit;
  our @ISA = qw(Date::Piece::unit_base);
  use constant unit => 'years';
  package Date::Piece::month_unit;
  our @ISA = qw(Date::Piece::unit_base);
  use constant unit => 'months';
  # Hmm, weeks are just 7 and days are just 1?
  # but do we want to be able to add weeks together first?
  package Date::Piece::week_unit;
  use constant unit => 'weeks';
  our @ISA = qw(Date::Piece::unit_base);
  package Date::Piece::day_unit;
  use constant unit => 'days';
  our @ISA = qw(Date::Piece::unit_base);
}
# now to redo the overloading here

=head2 _add

  $date = $date->_add($thing);

=cut

sub _add {
  my $self = shift;
  my ($and) = @_;
  if(ref($and) and $and->can('unit')) {
    my $m = '_add_' . $and->unit;
    croak("cannot add ", $and->unit) unless($self->can($m));
    return($self->$m($$and))
  }

  return($self->SUPER::_add($and));
} # end subroutine _add definition
########################################################################

sub _add_days {shift(@_)+shift(@_);}
sub _add_weeks {shift(@_)+shift(@_)*7;}
sub _add_months {shift->add_months(@_);}
sub _add_years {shift->add_years(@_);}
sub _add_centuries {shift->add_years(shift(@_)*100);}

=head2 _subtract

  $date = $date->_subtract($thing);

=cut

sub _subtract {
  my $self = shift;
  my ($and, $r) = @_;
  croak("cannot subtract a date from a non-date") if($r);
  if(ref($and) and $and->isa(__PACKAGE__)) {
    return($self->SUPER::_subtract($and, $r));
  }
  return($self->_add(-$and));
} # end subroutine _subtract definition
########################################################################

=head1 Examples

These all assume imported syntactical sugar ala:

  use Date::Piece qw(date today years months weeks);
  use Time::Piece;

Turning 40 is pretty arbitrary, but alarming!

  my $bd = date('1970-12-02');
  my $big40 = $bd+40*years;

  $SIG{ALRM} = sub { print "dude!  You're 'old' now.\n"; exit; }
  my $eggtimer = localtime - $big40->at('06:57');
  alarm($eggtimer);

  while(1) {
    my $countdown = $big40-today;
    print "$countdown days till the top of the hill\n";
    sleep(3600*24);
  }

Wake me when the ball drops (in my time zone.)

  my $date = today+1*years;
  $date = $date->start_of_year;
  $SIG{ALRM} = sub { print "Happy new year!\n"; exit; }
  alarm(localtime - $date->at('0s'));

=head1 Constructor

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
