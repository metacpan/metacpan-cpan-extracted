use strict;
use warnings;
package DateTime::Moonpig;
{
  $DateTime::Moonpig::VERSION = '1.03';
}
# ABSTRACT: a DateTime object with different math

use base 'DateTime';
use Carp qw(confess croak);
use overload
  '+' => \&plus,
  '-' => \&minus,
;
use Scalar::Util qw(blessed reftype);
use Sub::Install ();

use namespace::autoclean;

sub new {
  my ($base, @arg) = @_;
  my $class = ref($base) || $base;

  if (@arg == 1) { return $class->from_epoch( epoch => $arg[0] ) }

  my %arg = @arg;
  $arg{time_zone} = 'UTC' unless exists $arg{time_zone};
  bless $class->SUPER::new(%arg) => $class;
}

sub new_datetime {
  my ($class, $dt) = @_;
  bless $dt->clone => $class;
}

# $a is expected to be epoch seconds
sub plus {
  my ($self, $a) = @_;
  my $class = ref($self);
  my $a_sec = $class->_to_sec($a);
  return $class->from_epoch( epoch     => $self->epoch + $a_sec,
                             time_zone => $self->time_zone,
                           );
}

sub minus {
  my ($a, $b, $rev) = @_;
  # if $b is a datetime, the result is an interval
  # but if $b is an interval, the result is another datetime
  if (blessed($b)) {
    if ($b->can("as_seconds")) {
      croak "subtracting a date from a scalar object is forbidden"
        if $rev;
      return $a->plus( - $b->as_seconds );
    } elsif ($b->can("epoch")) {
      my $res = ( $a->epoch - $b->epoch ) * ($rev ? -1 : 1);
      return $a->interval_factory($res);
    } else {
      croak "Can't subtract X from $a when X has neither 'as_seconds' nor 'epoch' method";
    }
  } elsif (ref $b) {
    croak "Can't subtract unblessed " . reftype($b) . " reference from $a";
  } else { # $b is a number
    croak "subtracting a date from a number is forbidden"
      if $rev;
    return $a + (-$b);
  }
}

sub number_of_days_in_month {
  my ($self) = @_;
  return (ref $self)
          ->last_day_of_month(year => $self->year, month => $self->month)
          ->day;
}

for my $mutator (qw(
  add_duration subtract_duration
  truncate
  set
    _year _month _day _hour _minute _second _nanosecond
)) {
  (my $method = $mutator) =~ s/^_/set_/;
  Sub::Install::install_sub({
    code => sub { confess "Do not mutate DateTime objects! (http://rjbs.manxome.org/rubric/entry/1929)" },
    as   => $method,
  });
}

sub interval_factory { return $_[1] }

sub _to_sec {
  my ($self, $a) = @_;
  if (ref($a)) {
    if (blessed($a)) {
      if ($a->can('as_seconds')) {
        return $a->as_seconds;
      } else {
        croak "Can't add $self to object with no 'as_seconds' method";
      }
    } else {
      croak "Can't add $self to unblessed " . reftype($a) . " reference";
    }
  } else {
    return $a;
  }
}

sub precedes {
  my ($self, $d) = @_;
  return $self->compare($d) < 0;
}

sub follows {
  my ($self, $d) = @_;
  return $self->compare($d) > 0;
}

sub st {
  my ($self) = @_;
  join q{ }, $self->ymd('-'), $self->hms(':');
}

=head1 NAME 

DateTime::Moonpig - Saner interface to C<DateTime>

=head1 SYNOPSIS

	$birthday = DateTime::Moonpig->new( year   => 1969,
                                            month  =>    4,
                                            day    =>    2,
                                            hour   =>    2,
                                            minute =>   38,
                                          );
       $now = DateTime::Moonpig->new( time() );

       printf "%d\n", $now - $birthday;  # returns number of seconds difference

       $later   = $now + 60;     # one minute later
       $earlier = $now - 2*3600; # two hours earlier

       if ($now->follows($birthday)) { ... }    # true
       if ($birthday->precedes($now)) { ... }   # also true

=head1 DESCRIPTION

C<Moonpig::DateTime> is a thin wrapper around the L<DateTime> module
to fix problems with that module's design and interface.  The main
points are:

=over 4

=item *

Methods for mutating C<DateTime::Moonpig> objects in place have been
overridden to throw a fatal exception.  These include C<add_duration>
and C<subtract_duration>, C<set_>* methods such as C<set_hour>, and
C<truncate>.

=item *

The addition and subtraction operators have been overridden.

Adding a C<DateTime::Moonpig> to an integer I<n> returns a new
C<DateTime::Moonpig> equal to a time I<n> seconds later than the
original.  Similarly, subtracting I<n> returns a new C<DateTime::Moonpig> equal to a
time I<n> seconds earlier than the original.

Subtracting two C<DateTime::Moonpig>s returns the number of seconds elapsed between
them.  It does not return an object of any kind.

=item *

The C<new> method can be called with a single argument, which is
interpreted as a Unix epoch time, such as is returned by Perl's
built-in C<time()> function.

=item *

A few convenient methods have been added

=back

=head2 CHANGES TO C<DateTime> METHODS

=head3 C<new>

C<DateTime::Moonpig::new> is just like C<DateTime::new>, except:

=over 4

=item * The call

        DateTime::Moonpig->new( $n )

is shorthand for

        DateTime::Moonpig->from_epoch( epoch => $n )


=item *

If no C<time_zone> argument is specified, the returned object will be
created in the C<UTC> time zone.  C<DateTime> creates objects in its
"floating" time zone by default.  Such objects can be created via

        DateTime::Moonpig->new( time_zone => "floating", ... );

if you think that's what you really want. I advise against it because
a C<DateTime> object without an attached time zone has no definite
meaning.  It seems to refer to a particular time, but when pressed to
say what time it refers to, you can't.

=item *

C<new> can be called on a C<DateTime::Moonpig> object, which is then ignored. So for
example if C<$dtm> is any C<DateTime::Moonpig> object, then these two calls are
equivalent:

        $dtm->new( ... );
        DateTime::Moonpig->new( ... );

=back

=head3 Mutators are fatal errors

The following C<DateTime> methods will throw an exception if called:

        add_duration
        subtract_duration

        truncate

        set

        set_year
        set_month
        set_day
        set_hour
        set_minute
        set_second
        set_nanosecond

Rik has a sad story about why these are a bad idea:
L<http://rjbs.manxome.org/rubric/entry/1929>
(Summary: B<mutable state is the enemy>.)

The following mutators don't actually mutate the time value, and are allowed:

        set_time_zone
        set_locale
        set_formatter

The behavior of C<set_time_zone> is complicated by the C<DateTime>
module's handling of time zone changes.  It is possible to mutate a
time by setting its time zone to "floating" and then setting it again.
The normal behavior of C<DateTime>, to preserve the I<actual> time
represented by the object, is bypassed if you do this.

=head2 OVERLOADING

The overloading of all operators, except C<+> and C<->, is inherited
from C<DateTime>.

=head3 Summary

The C<+> and C<-> operators behave as follows:

=over 4

=item *

You can add a
C<DateTime::Moonpig> to a scalar, which will be interpreted as a number of seconds to
move forward in time. (Or backward, if negative.)

=item *

You can similarly subtract a scalar from a C<DateTime::Moonpig>. Subtracting a
C<DateTime::Moonpig> from a scalar is a fatal error.

=item *

You can subtract a C<DateTime::Moonpig> from another date object, such as another
C<DateTime::Moonpig>, or vice versa.  The result is the number of seconds between the
times represented by the two objects.

=item *

An object will be treated like a scalar if it implements an
C<as_seconds> method; it will be treated like a date object if it
implements an C<epoch> method.

=back

=head3 Full details

You can add a number to a C<DateTime::Moonpig> object, or subtract a number from a C<DateTime::Moonpig>
object; the number will be interpreted as a number of seconds to add
or subtract:

        # 1969-04-02 02:38:00
	$birthday = DateTime::Moonpig->new( year   => 1969,
                                            month  =>    4,
                                            day    =>    2,
                                            hour   =>    2,
                                            minute =>   38,
                                            second =>    0,
                                          );

	$x0    = $birthday + 10;         # 1969-04-02 02:38:10
	$x1    = $birthday - 10;         # 1969-04-02 02:37:50
	$x2    = $birthday + (-10);      # 1969-04-02 02:37:50

	$x3    = $birthday + 100;        # 1969-04-02 02:39:40
	$x4    = $birthday - 100;        # 1969-04-02 02:36:20

        # identical to $birthday + 100
	$x5    = 100 + $birthday;        # 1969-04-02 02:39:40

        # forbidden
	$x6    = 100 - $birthday;        # croaks

        # handy technique
        sub hours { $_[0} * 3600 }
	$x7    = $birthday + hours(12);  # 1969-04-02 14:38:00
	$x8    = $birthday - hours(12);  # 1969-04-01 14:38:00

C<$birthday> is I<never> modified by any of this.  The resulting objects will be in the same time zone as the original object, in this case UTC.

You can add any object to a C<DateTime::Moonpig> object if the other object supports an
C<as_seconds> method.  C<DateTime> and C<DateTime::Moonpig> objects do I<not> provide this method.

        package MyDaysInterval;                 # Silly example
	sub new {
	  my ($class, $days) = @_;
	  bless { days => $days } => $class;
        }

        sub as_seconds { $_[0]{days} * 86400 }

        package main;

        my $three_days = MyDaysInterval->new(3);

        $y0   = $birthday + $three_days;        # 1969-04-05 02:38:00

        # forbidden
        $y1   = $birthday + DateTime->new(...); # croaks
        $y2   = $birthday + $birthday;          # croaks

Again, C<$birthday> is not modified by any of this arithmetic.

You can subtract any object I<from> a C<DateTime::Moonpig> object, but
not vice versa, if that object provides an C<as_seconds> method.  It
will be interpreted as a time interval, and the result will be a new
C<DateTime::Moonpig> object:

        $z2   = $birthday - $three_days;     # 1969-03-30 02:38:00

	# forbidden
        $z3   = $three_days - $birthday;     # croaks

If you have another object that represents a time, and that implements
an C<epoch> method that returns its value as seconds since the Unix
epoch, you may subtract it from a C<DateTime::Moonpig> object or vice
versa. The result is the number of seconds between the second and the
first operands.  Since C<DateTime::Moonpig> implements C<epoch>, you
can subtract one C<DateTime::Moonpig> object from another to get the
number of seconds difference between them:

	$x0   = $birthday + 10;         # 1969-04-02 02:38:10

        $z4   = $x0 - $birthday;         # 10
        $z5   = $birthday - $x0;         # -10

        package Feb13;                  # Silly example
	sub new {
	  my ($class) = @_;
	  bless [ "DUMMY" ] => $class;
        }
        sub epoch { return 1234567890 } # Feb 13 23:31:30 2009 UTC

        package main;

        my $feb13 = Feb13->new();

        $feb13_dt = DateTime->new( year   => 2009,
                                   month  =>    2,
                                   day    =>   13,
                                   hour   =>   23,
                                   minute =>   31,
                                   second =>   30,
                                   time_zone => "UTC",
                                 );

        $z6   = $birthday - $feb13;     # -1258232010
        $z7   = $birthday - $feb13_dt;  # -1258232010
        $z8   = $feb13 - $birthday;     # 1258232010

        # WATCH OUT - will NOT return 1258232010
        $z9   = $feb13_dt - $birthday;  # returns a DateTime::Duration object

In this last example, C<DateTime>'s overloading is respected, rather than
C<DateTime::Moonpig>'s, and we get back a C<DateTime::Duration> object that represents
the elapsed difference of 40-some years.  Sorry, can't fix that; it's determined by Perl, which has to decide which of the two conflicting definitions of C<-> to honor, and chooses the other one.

None of these subtractions will modify any of the argument objects.

=head3 C<interval_factory>

When two time objects are subtracted, the result is normally a number.
However, the numeric difference is first passed to the target object's
C<interval_factory> method, which has the option to transform it and
return an object (or something else) instead.  The default
C<interval_factory> returns its argument unchanged.  So for example,

        $z0   = $x0 - $birthday;       # 10

is actually returning the result of C<< $x0->interval_factory(10) >>, which is 10.

=head3 Absolute time, not calendar time

C<DateTime::Moonpig> C<plus> and C<minus> always do real-time calculations, never civil
calendar calculations.  If your locality began observing daylight
savings on 2007-03-11, as most of the USA did, then:

        $a_day    = DateTime::Moonpig->new( year   => 2007,
                                            month  =>    3,
                                            day    =>   11,
                                            hour   =>    1,
                                            minute =>    0,
                                            second =>    0,
                                            time_zone => "America/New_York",
                                          );
	$next_day = $a_day->plus(24*3600);

At this point C<$next_day> is exactly 24E<middot>3600 seconds ahead
of C<$a_day>. Because the civil calendar day for 2007-03-11 in New
York was only 23 hours long, C<$next_day> represents represents
2007-03-12 02:00:00 instead of 2007-03-12 01:00:00. This should be what you
expect; if not please correct your expectation.

=head2 NEW METHODS

=head3 C<new_datetime>

C<< DateTime::Moonpig->new_datetime( $dt ) >> takes a C<DateTime> object and
returns an equivalent C<DateTime::Moonpig> object.

=head3 C<plus>, C<minus>

These methods implement the overloading for the C<+> and C<->
operators as per L<"OVERLOADING"> above.  See the L<overload> man
page for fuller details.

=head3 C<precedes>, C<follows>

	$a->precedes($b)
        $a->follows($b)

return true if time C<$a> is strictly earlier than time C<$b>, or
strictly later than time C<$b>, respectively.  If C<$a> and C<$b>
represent the same time, both methods will return false.  At most one will be
true for a given pair of dates. They are implemented as
calls to C<DateTime::compare>.

=head3 C<st>

Return a string representing the target time in the format

	1969-04-02 02:38:00

This is convenient and readable, but does not comply with ISO 8601.
It also omits the time zone, so beware.

The name C<st> is short for "string".

=head3 C<number_of_days_in_month>

This method takes no argument and returns the number of days in the
month it represents.  For example:

        DateTime::Moonpig->new( year  => 1969,
                                month =>    4,
                                day   =>    2,
                              )
            ->number_of_days_in_month()

returns 30.

=head3 C<interval_factory>

Used internally for manufacturing objects that represent time
intervals. See the description of the C<-> operator under
L<"OVERLOADING">, above.

=head1 BUGS

Please submit bug reports at
L<https://github.com/mjdominus/DateTime-Moonpig/issues>.

Please *do not* submit bug reports at C<http://rt.cpan.org/>.

=head1 LICENSE

Copyright E<copy> 2010 IC Group, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

See the C<LICENSE> file for a full statement of your rights under this
license.

=head1 AUTHOR

Mark Jason DOMINUS, C<mjd@cpan.org>

Ricardo SIGNES, C<rjbs@cpan.org>

=head2 WUT

C<DateTime::Moonpig> was originally part of the I<Moonpig> project,
where it was used successfully for several years before this CPAN
release.  For more complete details, see:

=over 4

=item *

L<http://blog.plover.com/prog/Moonpig.html> - Long blog article on the design and development of Moonpig generally.

=item *

L<http://perl.plover.com/yak/Moonpig/> - Slides and other materials
from a one-hour talk about Moonpig.

=item *

L<http://www.perladvent.org/2013/2013-12-23.html> - Perl 2013 Advent
Calendar article introducing this module and complaining about
C<DateTime::Duration>.

=back

=cut


1;
