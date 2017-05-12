# $Id: Business.pm,v 1.1 1999/12/28 22:05:38 desimr Exp desimr $
#
# $Log: Business.pm,v $
#
# Revision 1.2  1999/11/25 01:15:31  desimr
# added support for Holidays
#
# Revision 1.1  1999/11/23 18:11:55  desimr
# Business date package
#
# (c) 1999 Morgan Stanley Dean Witter and Co.
# See LICENSE for terms of distribution.
#
# Author: Richard DeSimine
# 
package Date::Business;

use strict;
use POSIX;
use Time::Local;
use vars qw($VERSION @ISA @EXPORT);
 
require Exporter;
require DynaLoader;
 
@ISA = qw(Exporter DynaLoader);

$VERSION = '1.2';
 
#RCS/CVS Version
my($RCSVERSION) = do {
  my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r
};

use constant DAY              => 86_400;
use constant WEEK             => DAY * 7;
use constant E_SUNDAY         => DAY * 3; # offset from Epoch Day Of Week
use constant THURSDAY         => 4;       # day of week
use constant FRIDAY           => 5;       # day of week
use constant SATURDAY         => 6;       # day of week
use constant SUNDAY           => 0;       # day of week

# create a new object with the specified date
# an offset in business days may be provided
sub new($;$$$) {
  my($class) = shift;
  my(%params) = @_;
  
  my($date)    = $params{DATE};    # string or Date object
  my($offset)  = $params{OFFSET};  # business days
  
  bless my $self = {'val' => 0}, $class;
  $self->{FORCE}   = $params{FORCE}   if (defined($params{FORCE}));
  $self->{HOLIDAY} = $params{HOLIDAY} if (ref($params{HOLIDAY}) eq 'CODE');
  
  # is the date parameter another Date::Business object?
  if (ref($date) eq __PACKAGE__) {
    $self->{val}       = $date->{val};
    $self->{FORCE}   ||= $date->{FORCE}   if (defined($date->{FORCE}));
    $self->{HOLIDAY} ||= $date->{HOLIDAY} if (ref($date->{HOLIDAY}) eq 'CODE');
  } else {
    # if not a Date::Business object is it a date string?
    if (defined($date) && length($date) != 0) {
      $self->{'val'} = image2value($date);
    } else {
      # else use current localtime
      my($lt) = timegm(localtime());
      $self->{'val'} = $lt - ($lt % DAY);
    }
  }
  
  # compute offset if specified
  if (defined($offset)) {    
    $self->addb($offset)  if ($offset > 0);
    $self->subb(-$offset) if ($offset < 0);
  } else {
    # if the date was initialized with a weekend or holiday
    # and the FORCE option is set, force it to the 'next'
    # or 'prev' business day
    if (defined($params{FORCE})) {
      if ($self->day_of_week == SATURDAY || $self->day_of_week == SUNDAY ||
	  (ref($self->{HOLIDAY}) eq 'CODE' && 
	   $self->{HOLIDAY}->($self->image, $self->image))) {
	$self->prevb if ($self->{FORCE} eq 'prev');
	$self->nextb if ($self->{FORCE} eq 'next');
      }
    }
  }
  return $self;
}

sub image2value($;$) {
  my($image) = @_;

  $image =~ m/(....)(..)(..)/;
  return timegm(0, 0, 0, $3, ($2-1), $1 - 1900);
}  

sub value($) {
  my($self) = @_;
  return $self->{'val'};
}  

sub image($) {
  my($self) = @_;
  return POSIX::strftime("%Y%m%d", gmtime($self->{'val'}));
}  

sub next(;$) {
  my($self, $n) = @_;
  $n = 1 if (!defined($n));
  $self->{'val'} += DAY * $n;
}

sub prev(;$) {
  my($self, $n) = @_;
  $n = 1 if (!defined($n));
  $self->{'val'} -= (DAY * $n);
}

sub datecmp($$) {
  my($self, $other) = @_;

  return $self->{'val'} <=> $other->{'val'};
}

sub eq($$) {
  my($self, $other) = @_;

  return $self->{'val'} <=> $other->{'val'};
}

sub gt($$) {
  my($self, $other) = @_;
  return $self->{'val'} > $other->{'val'};
}

sub lt($$) {
  my($self, $other) = @_;
  return $self->{'val'} < $other->{'val'};
}

sub add($$) {
  my($self, $inc) = @_;
  $self->{'val'} += $inc * DAY;
}

sub sub($$) {
  my($self, $inc) = @_;
  $self->{'val'} -= $inc * DAY;
}

sub diff($$) {
  my($self, $other) = @_;

  return int(($self->{'val'} - $other->{'val'}) / DAY);
}

sub day_of_week($$) {
  my($self) = @_;
  return (gmtime($self->{'val'}))[6];
}


# business date functions
sub nextb() {
  my($self) = @_;
  $self->addb(1);
}

sub prevb() {
  my($self) = @_;
  $self->subb(1);
}

# takes a reference to $self and a reference
# to an object of type Date::Business and returns
# the difference in business days
sub diffb($$;$$) {
  my($self, $other, $force_self, $force_other) = @_;
  return -1 if (!defined($other));
  my($days, $o_val, $sval, $tmp, $dow);
  my($sign) = 1;
  
  $force_self  ||= 'prev';
  $force_other ||= 'prev';

  $sval = $self->{val};
  while ($force_self eq 'prev') {
    $tmp = $sval;
    $dow = (gmtime($sval))[6];
    $sval -= 2 * DAY if ($dow == SUNDAY);
    $sval -= 1 * DAY if ($dow == SATURDAY);
    $sval -= 1 * DAY if (ref($self->{HOLIDAY}) eq 'CODE' && 
			 $self->{HOLIDAY}->(POSIX::strftime("%Y%m%d", gmtime($sval)),
					    POSIX::strftime("%Y%m%d", gmtime($sval))));
    last if ($sval == $tmp);
  }  
  while ($force_self eq 'next') {
    $tmp = $sval;
    $dow = (gmtime($sval))[6];
    $sval += 1 * DAY if ($dow == SUNDAY);
    $sval += 2 * DAY if ($dow == SATURDAY);
    $sval += 1 * DAY if (ref($self->{HOLIDAY}) eq 'CODE' && 
		   $self->{HOLIDAY}->(POSIX::strftime("%Y%m%d", gmtime($sval)),
				      POSIX::strftime("%Y%m%d", gmtime($sval))));
    last if ($sval == $tmp);
  }
  
  $o_val = $other->{val};
  while ($force_other eq 'prev') {
    $tmp = $o_val;
    $dow = (gmtime($o_val))[6];
    $o_val -= 2 * DAY if ($dow == SUNDAY);
    $o_val -= 1 * DAY if ($dow == SATURDAY);
    $o_val -= 1 * DAY if (ref($other->{HOLIDAY}) eq 'CODE' && 
			  $other->{HOLIDAY}->(POSIX::strftime("%Y%m%d", gmtime($o_val)),
					      POSIX::strftime("%Y%m%d", gmtime($o_val))));
    last if ($o_val == $tmp);
  }  
  while ($force_other eq 'next') {
    $tmp = $o_val;
    $dow = (gmtime($o_val))[6];
    $o_val += 1 * DAY if ($dow == SUNDAY);
    $o_val += 2 * DAY if ($dow == SATURDAY);
    $o_val += 1 * DAY if (ref($other->{HOLIDAY}) eq 'CODE' && 
			  $other->{HOLIDAY}->(POSIX::strftime("%Y%m%d", gmtime($o_val)),
					      POSIX::strftime("%Y%m%d", gmtime($o_val))));
    last if ($o_val == $tmp);
  }
  
  if ($sval < $o_val){
    $sign = -1;
  } else {
    $tmp = $sval;
    $sval = $o_val;
    $o_val = $tmp;
  }
  
  my($weeks) = int((($o_val - $sval)/WEEK)) * 5;
  $days = ((($o_val + E_SUNDAY) / DAY) % 7) - ((($sval + E_SUNDAY)/ DAY) % 7);
  $days += 5 if ($days < 0);

  if (ref($other->{HOLIDAY}) eq 'CODE') {
    $days -= $self->{HOLIDAY}->(POSIX::strftime("%Y%m%d", gmtime($sval)),
				POSIX::strftime("%Y%m%d", gmtime($o_val)));
  }
  return $sign * ($weeks + $days);
}

# adds n business days
sub addb($$) {
  my($self, $inc) = @_;

  return if ($inc == 0 || $inc < 0 && $self->subb(-$inc));

  my($start) = $self->{'val'};
  my($weeks) = int($inc/5) * 7;
  my($dow)   = (($self->{'val'} + E_SUNDAY) / DAY) % 7;
  my($days)  = $inc % 5;
  if ($dow > THURSDAY) {
    $self->{'val'} -= 1 * DAY if ($dow == FRIDAY);
    $self->{'val'} -= 2 * DAY if ($dow == SATURDAY);
    $dow-- if ($days == 0);
  }
  $days += 2 if ($days + $dow > THURSDAY);
  $self->{'val'} += ($weeks + $days) * DAY;

  if (ref($self->{HOLIDAY}) eq 'CODE') {
      my($start_txt) = POSIX::strftime("%Y%m%d", gmtime($start + DAY));
      my($numHolidays) = $self->{HOLIDAY}->($start_txt, $self->image);
      $self->addb($numHolidays) if ($numHolidays);
  }
  return 1;
}

# subs n business days
sub subb($$) {
  my($self, $dec) = @_;

  return if ($dec == 0 || $dec < 0 && $self->addb(-$dec));

  my($start) = $self->{'val'};
  my($weeks) = int($dec/5) * 7;
  my($dow)   = (($self->{'val'} + E_SUNDAY) / DAY) % 7;
  my($days)  =  $dec % 5;
  if ($dow > 4) {
    $self->{'val'} += 2 * DAY if ($dow == FRIDAY);
    $self->{'val'} += 1 * DAY if ($dow == SATURDAY);
    $days += 2 if ($days);
  } else {
    $days += 2 if ($days > $dow);
  }
  $self->{'val'} -= ($weeks + $days) * DAY;

  if (ref($self->{HOLIDAY}) eq 'CODE') {
      my($end_txt) = POSIX::strftime("%Y%m%d", gmtime($start - DAY));
      my($numHolidays) = $self->{HOLIDAY}->($self->image, $end_txt);
      $self->subb($numHolidays) if ($numHolidays);
  }
  return 1;
}
1;
__END__

=head1 NAME

  Date::Business - fast calendar and business date calculations

=head1 SYNOPSIS

  All arguments to the Date::Business constructor are optional.

  # simplest case, default is today's date (localtime)
  $d = new Date::Business();           

  # initialize with date string, 
  # offset in business days is optional
  $d = new Date::Business(DATE => '19991124' [, OFFSET => <integer>]); 

  # initialize with another Date::Business object
  # offset in business days is optional
  $x = new Date::Business(DATE => $d [, OFFSET => <integer>]);         

  # initialize with holiday function (see Holidays, below)
  $d = new Date::Business(HOLIDAY => \&holiday); 

  # force weekends/holidays to the previous or next business day
  $d = new Date::Business(FORCE => 'prev'); # Friday (usually)
  $d = new Date::Business(FORCE => 'next'); # Monday (usually)

  $d->image(); # returns YYYYMMDD string
  $d->value(); # returns Unix time as integer

  $d->day_of_week();     # 0 = Sunday

  $d->datecmp($x);       # are two dates equal?
  $d->eq($x);            # synonym for datecmp
  $d->lt($x);            # less than
  $d->gt($x);            # greater than

  Calendar date functions
  $d->next();         # next calendar day
  $d->prev();         # previous calendar day
  $d->add(<offset>);  # adds n calendar days
  $d->sub(<offset>);  # subtracts n calendar days
  $d->diff($x);       # difference between two dates  
    
  Business date functions
  $d->nextb();        # next business day
  $d->prevb();        # previous business day
  $d->addb(<offset>); # adds n business days
  $d->subb(<offset>); # subtracts n business days
  $d->diffb($x);      # difference between two business dates  
  $d->diffb($x, 'next'); # treats $d weekend/holiday as next business date
  $d->diffb($x, 'next', 'next'); # treats $x weekend/holiday as above


=head1 DESCRIPTION

Date::Business provides the functionality to perform simple date
manipulations quickly. Support for calendar date and
business date math is provided.

Business dates are weekdays only. Adding 1 to a weekend returns
Monday, subtracting 1 returns Friday.

The difference in business days between Friday and the following
Monday (using the diffb function) is one business day. The number
of business days between Friday and the following Monday (using the
betweenb function) is zero.

=head1 EXAMPLE

Date::Business works very well for iterating over dates,
and determining start and end dates of arbitray n business day
periods (e.g. consider how to perform a computation for
a series of business days starting from an arbitrary day).
 
 $end   = new Date::Business(); # today
 # 10 business days ago
 $start = new Date::Business(DATE => $end, OFFSET => -10); 

 while (!$start->gt($end)) {
   compute_something($start);
   $start->nextb();
 }

=head1 HOLIDAYS

Optionally, a reference to a function that counts the number of
holidays in a given date range can be passed. Business date addition,
subtraction, and difference functions will consider holidays.

Sample holiday function:

 # MUST BE NON-WEEKEND HOLIDAYS !!!
 sub holiday($$) {
    my($start, $end) = @_;
    
    my($numHolidays) = 0;
    my($holiday, @holidays);
    
    push @holidays, '19981225'; # Christmas
    push @holidays, '19990101'; $ New Year's
    
    foreach $holiday (@holidays) {
	$numHolidays++ if ($start le $holiday && $end ge $holiday);
    }
    return $numHolidays;
 }

Example using the holiday function:

 # 10 business days after 21 DEC 1998, where
 # 25 DEC 1998 and 01 JAN 1999 are holidays
 #
 $d = new Date::Business(DATE    => '19981221',
                         OFFSET  => 10,
                         HOLIDAY => \&holiday);

 print $d->image."\n"; # prints 19990106

=head1 The diffb() function explained

The difference between two business days is relatively straightforward
when the operands are business days. The difference (in business days)
between two days when one or both of those days is a weekend or
holiday is ambiguous. The 'next' and 'prev' parameters are used to
resolve the ambiguity.

The first parameter to the diffb function is the other date. The
second parameter indicates that 'self' is to be treated as the
previous or next business date if it is not a business date. The third
parameter is similar to the second parameter but applies to the
'other' date. The default behavior is treat both dates as if the
'prev' option was set.

For example:

 $d = new Date::Business(DATE => '19991225'); # saturday
 $x = new Date::Business(DATE => '19991225'); # saturday
 print $d->image;                     # prints 19991225
 print $d->diffb($x);                 # prints  0
 print $d->diffb($x, 'prev', 'next'); # prints -1
 print $d->diffb($x, 'next', 'prev'); # prints  1
 print $d->diffb($x, 'next', 'next'); # prints  0

=head1 CAVEATS

Business dates may be initialized with values in the range of
'19700101' through '20380119'. The range of valid results are
'19011213' through '20380119'.

Computations on dates that exceed the maximum value will wrap
around. (i.e. the day after '20380119' is '19011214'). Computations
that exceed the minimum value will result in the minimum
value. (i.e. the day before '19011213' is '19011213')

=cut
