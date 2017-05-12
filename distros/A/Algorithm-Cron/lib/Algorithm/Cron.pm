#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2014 -- leonerd@leonerd.org.uk

package Algorithm::Cron;

use strict;
use warnings;

our $VERSION = '0.10';

my @FIELDS = qw( sec min hour mday mon year wday );
my @FIELDS_CTOR = grep { $_ ne "year" } @FIELDS;

use Carp;
use POSIX qw( mktime strftime setlocale LC_TIME );
use Time::timegm qw( timegm );

=head1 NAME

C<Algorithm::Cron> - abstract implementation of the F<cron(8)> scheduling
algorithm

=head1 SYNOPSIS

 use Algorithm::Cron;

 my $cron = Algorithm::Cron->new(
    base => 'local',
    crontab => "*/10 9-17 * * *",
 );

 my $time = time;
 while(1) {
    $time = $cron->next_time( $time );

    sleep( time - $time );

    print "Do something\n";
 }

=head1 DESCRIPTION

Objects in this class implement a time scheduling algorithm such as used by
F<cron(8)>. Objects are stateless once constructed, and represent a single
schedule as defined by a F<crontab(5)> entry. The object implements a method
C<next_time> which returns an epoch timestamp value to indicate the next time
included in the crontab schedule.

=head2 Crontabs

The schedule is provided as a set of acceptable values for each field of the
broken-down time (as returned by C<localtime> or C<gmtime>), either in a
single string called C<crontab> or by a set of named strings, each taking the
name of a F<crontab(5)> field.

 my $cron = Algorithm::Cron->new(
    base => 'local',
    crontab => '0 9 * * mon-fri',
 );

Z<>

 my $cron = Algorithm::Cron->new(
    base => 'local',
    min  => 0,
    hour => 9,
    wday => "mon-fri",
 );

A C<crontab> field containing a single asterisk (C<*>), or a missing named
field, indicates that any value here is included in the scheduled times. To
restrict the schedule, a value or set of values can be provided. This should
consist of one or more comma-separated numbers or ranges, where a range is
given as the start and end points, both inclusive.

 hour => "3-6"
 hour => "3,4,5,6"

Ranges can also be prefixed by a value to give the increment for values in
that range.

 min => "*/10"
 min => "0,10,20,30,40,50"

The C<mon> and C<wday> fields also allow symbolic month or weekday names in
place of numeric values. These names are always in the C locale, regardless of
the system's locale settings.

 mon => "mar-sep"

 wday => "mon,wed,fri"

Specifying C<sun> as the end of a C<wday> range, or giving the numeric value
of C<7> is also supported.

 wday => "fri-sun"
 wday => "5-7"
 # Both equivalent to: wday => "0,5,6"

As per F<cron(8)> behaviour, this algorithm looks for a match of the C<min>,
C<hour> and C<mon> fields, and at least one of the C<mday> or C<mday> fields.
If both C<mday> and C<wday> are specified, a match of either will be
sufficient.

As an extension, seconds may be provided either by passing six space-separated
fields in the C<crontab> string, or as an additional C<sec> field. If not
provided it will default to C<0>. If six fields are provided, the first gives
the seconds.

=head2 Time Base

C<Algorithm::Cron> supports using either UTC or the local timezone when
comparing against the given schedule.

=cut

# mday field starts at 1, others start at 0
my %MIN = (
   sec  => 0,
   min  => 0,
   hour => 0,
   mday => 1,
   mon  => 0
);

# These don't have to be real maxima, as the algorithm will cope. These are
# just the top end of the range expansions
my %MAX = (
   sec  => 59,
   min  => 59,
   hour => 23,
   mday => 31,
   mon  => 11,
   wday => 6,
);

my %MONTHS;
my %WDAYS;
# These always want to be in LC_TIME=C
{
   my $old_loc = setlocale( LC_TIME );
   setlocale( LC_TIME, "C" );

   %MONTHS = map { lc(strftime "%b", 0,0,0, 1, $_, 70), $_ } 0 .. 11;

   # 0 = Sun. 4th Jan 1970 was a Sunday
   %WDAYS  = map { lc(strftime "%a", 0,0,0, 4+$_, 0, 70), $_ } 0 .. 6;

   setlocale( LC_TIME, $old_loc );
}

sub _expand_set
{
   my ( $spec, $kind ) = @_;

   return undef if $spec eq "*";

   my @vals;
   foreach my $val ( split m/,/, $spec ) {
      my $step = 1;
      my $end;

      $val =~ s{/(\d+)$}{} and $step = $1;

      $val =~ m{^(.+)-(.+)$} and ( $val, $end ) = ( $1, $2 );
      if( $val eq "*" ) {
         ( $val, $end ) = ( $MIN{$kind}, $MAX{$kind} );
      }
      elsif( $kind eq "mon" ) {
         # Users specify 1-12 but we want 0-11
         defined and m/^\d+$/ and $_-- for $val, $end;
         # Convert symbolics
         defined and exists $MONTHS{lc $_} and $_ = $MONTHS{lc $_} for $val, $end;
      }
      elsif( $kind eq "wday" ) {
         # Convert symbolics
         defined and exists $WDAYS{lc $_} and $_ = $WDAYS{lc $_} for $val, $end;
         $end = 7 if defined $end and $end == 0 and $val > 0;
      }

      $val =~ m/^\d+$/ or croak "$val is unrecognised for $kind";
      $end =~ m/^\d+$/ or croak "$end is unrecognised for $kind" if defined $end;

      push @vals, $val;
      push @vals, $val while defined $end and ( $val += $step ) <= $end;

      if( $kind eq "wday" && $vals[-1] == 7 ) {
         unshift @vals, 0 unless $vals[0] == 0;
         pop @vals;
      }
   }

   return \@vals;
}

use constant { EXTRACT => 0, BUILD => 1, NORMALISE => 2 };
my %time_funcs = (
              # EXTRACT                BUILD     NORMALISE
   local => [ sub { localtime $_[0] }, \&mktime, sub { localtime mktime @_[0..5], -1, -1, -1 } ],
   utc   => [ sub { gmtime $_[0] },    \&timegm, sub { gmtime timegm @_[0..5], -1, -1, -1 } ],
);

# Indices in time array
use constant {
   TM_SEC  => 0,
   TM_MIN  => 1,
   TM_HOUR => 2,
   TM_MDAY => 3,
   TM_MON  => 4,
   TM_YEAR => 5,
   TM_WDAY => 6,
};

=head1 CONSTRUCTOR

=cut

=head2 $cron = Algorithm::Cron->new( %args )

Constructs a new C<Algorithm::Cron> object representing the given schedule
relative to the given time base. Takes the following named arguments:

=over 8

=item base => STRING

Gives the time base used for scheduling. Either C<utc> or C<local>.

=item crontab => STRING

Gives the crontab schedule in 5 or 6 space-separated fields.

=item sec => STRING, min => STRING, ... mon => STRING

Optional. Gives the schedule in a set of individual fields, if the C<crontab>
field is not specified.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $base = delete $params{base};
   grep { $_ eq $base } qw( local utc ) or croak "Unrecognised base - should be 'local' or 'utc'";

   if( exists $params{crontab} ) {
      my $crontab = delete $params{crontab};
      s/^\s+//, s/\s+$// for $crontab;

      my @fields = split m/\s+/, $crontab;
      @fields >= 5 or croak "Expected at least 5 crontab fields";
      @fields <= 6 or croak "Expected no more than 6 crontab fields";

      @fields = ( "0", @fields ) if @fields < 6;
      @params{ @FIELDS_CTOR } = @fields;
   }

   $params{sec} = 0 unless exists $params{sec};

   my $self = bless {
      base => $base,
   }, $class;

   foreach ( @FIELDS_CTOR ) {
      next unless exists $params{$_};

      $self->{$_} = _expand_set( delete $params{$_}, $_ );
      !defined $self->{$_} or scalar @{ $self->{$_} } or
         croak "Require at least one value for '$_' field";
   }

   return $self;
}

=head1 METHODS

=cut

=head2 @seconds = $cron->sec

=head2 @minutes = $cron->min

=head2 @hours = $cron->hour

=head2 @mdays = $cron->mday

=head2 @months = $cron->mon

=head2 @wdays = $cron->wday

Accessors that return a list of the accepted values for each scheduling field.
These are returned in a plain list of numbers, regardless of the form they
were specified to the constructor.

Also note that the list of valid months will be 0-based (in the range 0 to 11)
rather than 1-based, to match the values used by C<localtime>, C<gmtime>,
C<mktime> and C<timegm>.

=cut

foreach my $field ( @FIELDS_CTOR ) {
   no strict 'refs';
   *$field = sub {
      my $self = shift;
      @{ $self->{$field} || [] };
   };
}

sub next_time_field
{
   my $self = shift;
   my ( $t, $idx ) = @_;

   my $funcs = $time_funcs{$self->{base}};

   my $spec = $self->{ $FIELDS[$idx] } or return 1;

   my $old = $t->[$idx];
   my $new;

   $_ >= $old and $new = $_, last for @$spec;

   # wday field is special. We can't alter it directly; any changes to it have
   # to happen via mday
   if( $idx == TM_WDAY ) {
      $idx = TM_MDAY;
      # Adjust $new by the same delta
      $new = $t->[TM_MDAY] + $new - $old if defined $new;
      $old = $t->[TM_MDAY];

      if( !defined $new ) {
         # Next week
         $t->[$_] = $MIN{$FIELDS[$_]} for TM_SEC .. TM_HOUR;
         # Add more days, such that we hit the next occurance of $spec->[0]
         $t->[TM_MDAY] += $spec->[0] + 7 - $t->[TM_WDAY];

         @$t = $funcs->[NORMALISE]->( @$t );

         return 0;
      }
      elsif( $new > $old ) {
         $t->[$_] = $MIN{$FIELDS[$_]} for TM_SEC .. $idx-1;
      }
   }
   else {
      if( !defined $new ) {
         # Rollover
         $t->[$_] = $MIN{$FIELDS[$_]} for TM_SEC .. $idx-1;
         $t->[$idx] = $spec->[0];
         $t->[$idx+1]++;

         @$t = $funcs->[NORMALISE]->( @$t );

         return 0;
      }
      elsif( $new > $old ) {
         # Next field; reset
         $t->[$_] = $MIN{$FIELDS[$_]} for TM_SEC .. $idx-1;
      }
   }

   $t->[$idx] = $new;

   # Detect rollover of month and reset to next month
   my $was_mon = $t->[TM_MON];

   @$t = $funcs->[NORMALISE]->( @$t );

   if( $idx == TM_MDAY and $was_mon != $t->[TM_MON] ) {
      $t->[$_] = 0 for TM_SEC .. TM_HOUR;
      $t->[TM_MDAY] = 1;

      @$t = $funcs->[NORMALISE]->( @$t );

      return 0;
   }

   return 1;
}

=head2 $time = $cron->next_time( $start_time )

Returns the next scheduled time, as an epoch timestamp, after the given
timestamp. This is a stateless operation; it does not change any state stored
by the C<$cron> object.

=cut

sub next_time
{
   my $self = shift;
   my ( $time ) = @_;

   my $funcs = $time_funcs{$self->{base}};

   # Always need to add at least 1 second
   my @t = $funcs->[EXTRACT]->( $time + 1 );

RESTART:
   $self->next_time_field( \@t, TM_MON ) or goto RESTART;

   if( defined $self->{mday} and defined $self->{wday} ) {
      # Now it gets tricky because cron allows a match of -either- mday or wday
      # rather than requiring both. So we'll work out which of the two is sooner
      my $next_time_by_wday;
      my @wday_t = @t;
      my $wday_restart = 0;
      $self->next_time_field( \@wday_t, TM_WDAY ) or $wday_restart = 1;
      $next_time_by_wday = $funcs->[BUILD]->( @wday_t );

      my $next_time_by_mday;
      my @mday_t = @t;
      my $mday_restart = 0;
      $self->next_time_field( \@mday_t, TM_MDAY ) or $mday_restart = 1;
      $next_time_by_mday = $funcs->[BUILD]->( @mday_t );

      if( $next_time_by_wday > $next_time_by_mday ) {
         @t = @mday_t;
         goto RESTART if $mday_restart;
      }
      else {
         @t = @wday_t;
         goto RESTART if $wday_restart;
      }
   }
   elsif( defined $self->{mday} ) {
      $self->next_time_field( \@t, TM_MDAY ) or goto RESTART;
   }
   elsif( defined $self->{wday} ) {
      $self->next_time_field( \@t, TM_WDAY ) or goto RESTART;
   }

   foreach my $idx ( TM_HOUR, TM_MIN, TM_SEC ) {
      $self->next_time_field( \@t, $idx ) or goto RESTART;
   }

   return $funcs->[BUILD]->( @t );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
