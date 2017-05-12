package DateTime::Fiscal::Retail454;

use strict;
use warnings;

our $VERSION = '0.03';

our $R454DEBUG = 0;

use Carp;

use DateTime;
use base qw(DateTime);

my $pkg = __PACKAGE__;

my @periodmonths = qw(
  February
  March
  April
  May
  June
  July
  August
  September
  October
  November
  December
  January
);

# This code ref builds a cache that can be used as long as the value in
# the _R454_basedate attribute remains unchanged.
my $_r454_build_periods = sub {
    my $self = shift;

    return
      if ref($self->{_R454_periods}) && $self->{_R454_basedate} eq $self->ymd;

    my @pweeks = (0, 4, 5, 4, 4, 5, 4, 4, 5, 4, 4, 5, 4);
    $pweeks[$#pweeks] = 5 if $self->is_r454_leap_year;

    my $pdata  = {};
    my $pstart = $pkg->_454_start($self->r454_year);

    for (1 .. 12) {
        $pdata->{$_} = {
            pstart   => $pstart->clone,
            weeks    => $pweeks[$_],
            r454year => $self->r454_year,
            month    => $periodmonths[$_ - 1]
        };
        my $pend =
          $pstart->clone->add(weeks => $pweeks[$_])->subtract(seconds => 1);
        $pdata->{$_}->{pend} = $pend;
        my $ppub = $pend->clone->truncate(to => 'day')->add(days => 5);
        $pdata->{$_}->{ppub} = $ppub;

        $pstart = $pstart->clone->add(weeks => $pweeks[$_]);
    }

    $self->{_R454_periods}  = $pdata;
    $self->{_R454_basedate} = $self->ymd;

};

# this code ref is used with versions of DateTime prior to 0.64
my $_454_allocate = sub {
    my $self = shift;

    $self->{_R454_year}    = undef;
    $self->{_R454_periods} = undef;

    return;
};

# this override is required for versions of DateTime starting with 0.64
# and serves the same purpose as the above code reference, but in a
# much nicer way.
sub _new
{
    my $proto  = shift;
    my %params = @_;

    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::_new(%params);
    $self->{_R454_year}    = undef;
    $self->{_R454_periods} = undef;

    return $self;
}

sub _454_start
{
    my $proto = shift;
    my $cyr   = shift;

    my ($package, $filename, $line) = caller;
    confess "FORBIDDEN private method call" unless $package->isa($pkg);

    my $class = ref($proto) || $proto;

    #  my $r454tmp = $pkg->SUPER::new( year => $cyr, month => 1, day => 31 );
    my $r454tmp = $class->SUPER::new(year => $cyr, month => 1, day => 31);
    my $jan31dow = $r454tmp->dow;
    if ($jan31dow < 3) {
        $r454tmp->subtract(days => $jan31dow);
    } elsif ($jan31dow < 7) {
        $r454tmp->add(days => (7 - $jan31dow));
    }

    return $r454tmp;
}

sub from_r454year
{
    my $proto  = shift;
    my %params = @_;

    croak "Mandatory parameter 'r454year' missing"
      unless defined($params{r454year});

    my $class = ref($proto) || $proto;

    #return( bless $pkg->_454_start($params{r454year}), $proto )
    return $class->_454_start($params{r454year});
}

# These have to be overloaded here in order to properly setup any attributes
# used by this module.  In addition, 'from_day_of_year' has to be here
# because it does not ever call the normal 'new' constructor.
#
# NOTE!!!
# It appears that DateTime calls new any time a change is made to the object's
# value, through actions such as date math or the 'set' functions.
# OTOH, the object is left alone for any of the 'get' functions.
#
# Because of this, care must be taken to ensure a recursive loop isn't
# created, hence the need for a seperate constructor for 'from_r454year'.
#
# NOTE!!!
# The internals of DateTime have changed in version 0.64 which makes
# sub-classing much easier. This code has been changed accordingly to
# try to pick up which style is being used in DateTime.
#
# Even so, I am poking around under the hood and can be bit in the future.

sub new
{
    my $proto  = shift;
    my %params = @_;

    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%params);

    #  &{$_454_allocate}($self);
    &{$_454_allocate}($self) unless exists($self->{_R454_year});

    return ($self);
}

# this override is needed because the constructor in earlier versions of
# DateTime did not propagate sub-classing.
sub from_day_of_year
{
    my $proto  = shift;
    my %params = @_;

    my $class = ref($proto) || $proto;

    #  my $self = bless $pkg->SUPER::from_day_of_year(%params), $proto;
    my $self = $class->SUPER::from_day_of_year(%params);
    bless $self, $class unless ref($self) eq $class;

    #  &{$_454_allocate}($self);
    &{$_454_allocate}($self) unless exists($self->{_R454_year});

    return ($self);
}

sub r454_year
{
    my $self = shift;

    if (!defined($self->{_R454_year})) {
        my $r454tmp = $pkg->_454_start($self->year);
        $self->{_R454_year} =
          $r454tmp > $self ? $self->year - 1 : $r454tmp->year;
    }

    return ($self->{_R454_year});
}

sub is_r454_leap_year
{
    my $self = shift;

    my $tmpnext = $pkg->_454_start($self->r454_year)->add(days => 364);
    my $realnext = $pkg->_454_start($self->r454_year + 1);

    return ($realnext > $tmpnext ? 1 : 0);
}

sub r454_start
{
    my $self   = shift;
    my %params = @_;

    my $asobj = (defined($params{as_obj}) ? $params{as_obj} : 0);

    my $r454start = $pkg->_454_start($self->r454_year);

    return ($asobj ? $r454start : "" . $r454start);
}

sub r454_end
{
    my $self   = shift;
    my %params = @_;

    my $asobj = (defined($params{as_obj}) ? $params{as_obj} : 0);

    my $r454end =
      $pkg->_454_start($self->r454_year + 1)->subtract(seconds => 1);

    return ($asobj ? $r454end : "" . $r454end);
}

sub r454_period
{
    my $self   = shift;
    my %params = @_;

    my $asobj = defined($params{as_obj}) ? $params{as_obj} : 0;
    carp "objects requested in non-array context" if $asobj && !wantarray;

    my $pnum = defined($params{period}) ? 0 + $params{period} : 0;

    &{$_r454_build_periods}($self);

    if (!$pnum) {
        $pnum = 1;
        while ($self->{_R454_periods}->{$pnum}->{pstart} < $self) {
            last if $self->{_R454_periods}->{$pnum + 1}->{pstart} > $self;
            last if ++$pnum == 12;
        }
    }
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    return ($pnum) unless wantarray;

    my $phash = $self->{_R454_periods}->{$pnum};
    my @pdata = (
        $pnum,
        $phash->{weeks},
        ($asobj ? $phash->{pstart}->clone : "" . $phash->{pstart}),
        ($asobj ? $phash->{pend}->clone   : "" . $phash->{pend}),
        ($asobj ? $phash->{ppub}->clone   : "" . $phash->{ppub}),
        $phash->{r454year}
    );

    return (@pdata);
}

sub r454_period_weeks
{
    my $self   = shift;
    my %params = @_;

    my $pnum =
      defined($params{period}) ? 0 + $params{period} : $self->r454_period;
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    &{$_r454_build_periods}($self);

    return ($self->{_R454_periods}->{$pnum}->{weeks});
}

sub r454_period_start
{
    my $self   = shift;
    my %params = @_;

    my $asobj = defined($params{as_obj}) ? $params{as_obj} : 0;
    my $pnum =
      defined($params{period}) ? 0 + $params{period} : $self->r454_period;
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    &{$_r454_build_periods}($self);
    my $pobj = $self->{_R454_periods}->{$pnum}->{pstart};

    return ($asobj ? $pobj : "" . $pobj);
}

sub r454_period_end
{
    my $self   = shift;
    my %params = @_;

    my $asobj = defined($params{as_obj}) ? $params{as_obj} : 0;
    my $pnum =
      defined($params{period}) ? 0 + $params{period} : $self->r454_period;
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    &{$_r454_build_periods}($self);
    my $pobj = $self->{_R454_periods}->{$pnum}->{pend}->clone;

    return ($asobj ? $pobj : "" . $pobj);
}

sub r454_period_publish
{
    my $self   = shift;
    my %params = @_;

    my $asobj = defined($params{as_obj}) ? $params{as_obj} : 0;
    my $pnum =
      defined($params{period}) ? 0 + $params{period} : $self->r454_period;
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    &{$_r454_build_periods}($self);
    my $pobj = $self->{_R454_periods}->{$pnum}->{ppub}->clone;

    return ($asobj ? $pobj : "" . $pobj);
}

sub r454_period_month
{
    my $self   = shift;
    my %params = @_;

    my $pnum =
      defined($params{period}) ? 0 + $params{period} : $self->r454_period;
    croak "Invalid Period specified" unless $pnum > 0 && $pnum < 13;

    &{$_r454_build_periods}($self);

    return ($self->{_R454_periods}->{$pnum}->{month});
}

sub truncate
{
    my $self   = shift;
    my %params = @_;

    if ($params{to} eq 'r454year') {
        my $tmp = $self->r454_start(as_obj => 1);
        %{$self} = %{$tmp};
    } elsif ($params{to} eq 'period') {
        my $tmp = $self->r454_period_start(as_obj => 1);
        %{$self} = %{$tmp};
    } else {
        $self->SUPER::truncate(%params);
    }

    return ($self);
}

1;

__END__

=head1 NAME

DateTime::Fiscal::Retail454 - create 4-5-4 Calendar data from DateTime objects.

=head1 DEPRECATED

This module has been deprecated! Please use L<DateTimeX::Fiscal::Fiscal5253>
instead. The new module has enhanced support for NRF 4-5-4 calenders as well
as for 52/53 week fiscal years in general.

=head1 SYNOPSIS

 use DateTime::Fiscal::Retail454;
 
 my $r454 = DateTime::Fiscal::Retail454->new( year => 2006 );
 
 my $fiscalyear = $r454->r454_year; # Might NOT be what you expect!
 
 if ( $r454->is_r454_leap_year ) {
   # do something here
 }

 my $startdate = $r454->r454_start;		# start of fiscal year
 my $enddate = $r454->r454_end;			# end of fiscal year

 my @fiscalperiod_data = $r454->r454_period;	# returns all period data
 my $fp_number = $r454->r454_period;		# returns period number

 my $fp_weeks = $r454->r454_period_weeks;	# number of weeks in period
 my $fp_start = $r454->r454_period_start;	# period start date
 my $fp_end = $r454->r454_period_end;		# period end date
 my $fp_end = $r454->r454_period_publish;	# period publish date
 
See the details below for each method for options.

=head1 DESCRIPTION

This module is a sub-class of C<DateTime> and inherits all methods and
capabilities, including constructors, of that module.

The purpose of this module is to make it easy to work with the 4-5-4
calendar that is common among merchandisers.  Details of the calendar itself
can be found at the National Retail Federation (NRF) website.
L<http://www.nrf.com/modules.php?name=Pages&sp_id=391>

All objects returned by any of the methods in this module or of the class
C<DateTime::Fiscal::Retail454> unless otherwise specified.

=head1 EXPORTS

None.

=head1 DEPENDENCIES

 Carp
 DateTime

=head1 CONSTRUCTORS

All of the constructors from the parent C<DateTime> class can be used to
obtain a new object.

In addition,  an additional constructor named C<from_r454year> has been added.

=head2 from_r454year

 my $r454 = DateTime::Fiscal::Retail454->from_r454year( r454year => 2000 );

Returns an object of type C<DateTime::Fiscal::Retail454> with a value of the
first day in the specified RETAIL year.
The C<r454year> parameter is B<mandatory> and an exception will result if it
is missing.

The returned object  will have a date in the range
'YYYY-01-29' - 'YYYY-02-04' depending on what day of the week Jan 31 of the
specified year YYYY falls on.

The algorythm for selecting the starting date can be stated as follows:

Obtain the day of the week for Jan 31 of the specified year as a number in
the range 1 - 7 where Monday = 1, Tuesday = 2, etc.

If the day of the week is < 3, then subtract that number of days from Jan 31
to obtain the date of the preceding Sunday as the starting date.

If the day of the week is < 7, then first substract that number from 7, and
then add the resulting number of days to Jan 31 to obtain the date of the
following Sunday as the starting date.

If the day of the week is 7 (or Sunday) then no further changes are needed and
the starting date is in fact YYYY-01-31 for that year.

=head1 METHODS

=head2 r454_year

 my $r454 = DateTime::Fiscal::Retail454->new( year => 2006, month = 4 );
 print $r454->r454_year;	# print "2006"
 
 my $r454_2 = DateTime::Fiscal::Retail454->new( year => 2006, month = 1 );
 print $r454->r454_year;	# print "2005"

Returns a scalar containing the Fiscal Year that the object is in.  This is
not always the same as the calendar year, especially for dates in January and
occasionally in February.  This is because the start of the Fiscal Year is
tied to what day of the week Jan 31 of any given year falls on.

=head2 is_r454_leap_year

 my $r454 = DateTime::Fiscal::Retail454->new( r454year => 2006 );
 print "This is a Fiscal Leap Year" if $r454->is_r454_leap_year;

Returns a Boolean value indicating whether or not the Fiscal Year for the
object has 53 weeks instead of the standard 52 weeks.

=head2 r454_start

  my $startdate = $r454->r454_start;
  my $startobj = $r454->r454_start( as_obj => 1 );

Returns the starting date for the object's Fiscal Year as either a string or
an object as specified by the C<as_obj> parameter (default is string).

=head2 r454_end

  my $enddate = $r454->r454_end;
  my $endobj = $r454->r454_end( as_obj => 1 );

Returns the ending date for the object's Fiscal Year as either a string or
an object as specified by the C<as_obj> parameter (default is string).

=head2 r454_period

This is the workhorse method and can be called in several ways.

 # Return the current R454 period number
 my $fp_number = $r454->r454_period;
 
 # Return a list containing all data for the current period.
 # The array is
 # ( fp_number, fp_weeks, fp_start, fp_end, fp_publish, fp_year ).
 my @fp_data = $r454->r454_period;
 
 # As above but with objects for fp_start and fp_end instead of strings
 my @fp_data = $r454->r454_period( as_obj => 1 );
 
 # Specify the period for which data is returned.
 my @fp_data = $r454->r454_period( period => 5 );
 my @fp_data = $r454->r454_period( period => 5, as_obj => 1 );

As can be seen above, the calling context affects the return values.
When called in scalar context it defaults to returning a scalar containing
the current period number for the calling object.
When called in list context it returns a list containing all avaiable data
for a period. The list is structured as follows:

 ( fp_number, fp_weeks, fp_start, fp_end, fp_publish, fp_year )

If the C<as_obj> parameter is specified the values for C<fp_start> and
C<fp_end> will objects of class C<DateTime::Fiscal::Retail454>.

A specific period may be requested by using the C<period> parameter.
Using this parameter with no others will result in that period number being
returned, probably not what you wanted.

Objects instead of strings may be specified by the C<as_obj> parameter.

The individual components for the number of weeks, starting date, ending
date and publish date may be obtained with the methods below if desired.
The R454 year may be obtained separately by using the C<r454_year> method.

=head3 r454_period_weeks

 my $fp_weeks = $r454->r454_period_weeks;
 my $fp_weeks = $r454->r454_period_weeks( period => 5 );

Returns a salar with the number of weeks in either the current or specified
period.

=head3 r454_period_start

 my $fp_start = $r454->r454_period_start;
 my $fp_startobj = $r454->r454_period_start( as_obj => 1);
 my $fp_start = $r454->r454_period_start( period => 5 );
 my $fp_startobj = $r454->r454_period_start( as_obj => 1, period => 5 );

Returns either a string (default) or object representing the start of the
current (default) or specified period.

=head3 r454_period_end

 my $fp_end = $r454->r454_period_end;
 my $fp_endobj = $r454->r454_period_end( as_obj => 1);
 my $fp_end = $r454->r454_period_end( period => 5 );
 my $fp_endobj = $r454->r454_period_end( as_obj => 1, period => 5 );

Returns either a string (default) or object representing the end of the
current (default) or specified period.

=head3 r454_period_publish

 my $fp_publish = $r454->r454_period_publish;
 my $fp_publishobj = $r454->r454_period_publish( as_obj => 1);
 my $fp_publish = $r454->r454_period_publish( period => 5 );
 my $fp_publishobj = $r454->r454_period_publish( as_obj => 1, period => 5 );

Returns either a string (default) or object representing the publish date
for the current (default) or specified period.

=head3 r454_period_month

 my $fp_month = $r454->r454_period_month;
 my $fp_month = $r454->r454_period_month( period => 5 );

Returns the nominal name of the month for the current or specified
period.

=head2 truncate

 $r454->truncate( to => 'r454year' );
 $r454->truncate( to => 'period' );

The C<truncate> method has been overloaded to add two new parameters as shown.
The new parameters set the object value to either C<r454_start> or
C<r454_period> as appropriate.

Any other parameters will result in a call to the parent class.

=head1 BUGS

You gotta be kidding! I'm human, of course there will be some.

=head1 TODO

Method(s) to return the R454 week_of_year data for an object.
 
Method(s) need to be added that generate comparison tables with  
R454 leap years restated or not as desired.
 
Method(s) to return the R454 period or week_of_year for various holidays.

=head1 SEE ALSO

=over

=item L<DataTimeX::Fiscal::Fiscal5253>

A replacement module for DateTime::Fiscal::Retail454 that has better methods,
more functionality and does not sub-class DateTime. Please use it instead.

=item L<DateTime>

The Retail 4-5-4 Calendar as descibed by the National Retail Federation
L<http://www.nrf.com/modules.php?name=Pages&sp_id=391>

=back

=head1 SUPPORT

Support is provided by the author. Please report bugs or make feature
requests to the email address below.

=head1 IMPORTANT NOTE

This module sub-classes L<DateTime> and pokes around under the hood in some
cases. That is the beauty (and curse) of perl.

A significant change in the internal structure of L<DateTime> around version
0.64 required corresponding changes to this module.  Be advised that this
can happen again in the future.

This module was developed using versions 0.36 and 0.76 of L<DateTime> on
two different platforms.

Please let me know of any problems you encounter. Be sure to include the
version number of L<DateTime> you are using.

=head1 AUTHOR

Jim Bacon, E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Bacon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR 
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR 
PURPOSE. 

The full text of the license can be found in the LICENSE file included
with this module.

=cut

