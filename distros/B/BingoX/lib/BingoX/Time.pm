# BingoX::Time
# -----------------
# $Revision: 1.10 $
# $Date: 2000/12/12 18:54:34 $
# ---------------------------------------------------------

=head1 NAME

BingoX::Time - Time display parent class containing generic methods

=head1 SYNOPSIS

use BingoX::Time;

CONSTRUCTORS

  $BR = $proto->new( [ $time ] [, $data_object ] );

OBJECT METHODS

  $date->month_full;
  $date->month_full2abrv;

  $date->months_list;
  $date->months_full_list;

  $date->months;
  $date->months_pad;
  $date->months_full;
  $date->months_full_pad;
  $date->month_abrv;

  $date->int_months;
  $date->int_months_full;

  $date->last_day;
  $date->last_days;

  $date->is_leap_year;

  $date->hours24;
  $date->hours;
  $date->minutes;

=head1 REQUIRES

 strict
 Date::Parse
 Date::Language
 Date::Language::English
 Time::Object

=head1 EXPORTS

localtime, gmtime

=head1 DESCRIPTION

Time provides an OO interface to Time/Dates, ala Time::Object.

=head1 METHODS

=over 4

=cut

package BingoX::Time;

use vars qw(@ISA @EXPORT $debug);
use strict;

use Date::Parse;
use Date::Language;
use Date::Language::English;


BEGIN {
	$BingoX::Time::REVISION	= (qw$Revision: 1.10 $)[-1];
	$BingoX::Time::VERSION	= '1.92';

	@ISA		= qw(Time::Object);
	@EXPORT		= qw(localtime gmtime);
	$debug		= undef;

	if ($debug) {
		require Data::Dumper;
	}
}

use Time::Object qw();


=item C<new> ( [ $time ] [, $islocal ] )

This is a Time::Object overloaded constructor that can take as values 
the time in seconds, or defaults to 'time'.  It can also take the $islocal 
flag, which tells _mktime() to use localtime (1) or gmtime (0).  It always 
returns a BingoX Time Object.

=cut
sub new {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $time	= shift;
	my $islocal	= shift;

	my $self;

	if (defined $time) {
		$self = _mktime( $time, (defined $islocal ? $islocal : 1), $class );
	} elsif (ref($proto) && $proto->isa('Time::Object')) {
		$self = _mktime($proto->[9], $proto->[10], $class);
	} else {
		$self = _mktime( time, (defined $islocal ? $islocal : 1), $class );
	}

	return bless $self, $class;
} # END sub new


=begin comment

_mktime(  )

This is a Time::Object overloaded constructor that take as values 
the time in seconds, and the $islocal flag, which tells it to use 
localtime (1) or gmtime (0).  It returns a BingoX Time Object 
or Time::Object depending on whether it was called from a sub class.  
If it was called as a 'wantarray' it will return the contents returned 
localtime, or gmtime depending on the $islocal flag.

=end comment

=cut
sub _mktime {
	my ($time, $islocal, $class) = @_;
	my @time = $islocal
			? CORE::localtime($time)
			: CORE::gmtime($time);
	wantarray ? @time : bless [@time, $time, $islocal], ($class->isa('Time::Object')
														? $class
														: 'Time::Object');
} # END sub _mktime


=item C<str2time> ( $string )

This is method is used to parse your default date format into a format 
that str2time understands, such as:

  Date: 961221               (yymmdd)
  Date: 12-21-96             (mm-dd-yy)    ( '-', '.' or '/' )
  Date: 12-June-96           (dd-month-yy) ( '-', '.' or '/' )
  Date: June 12 96 00:00PM   (month dd yy hh:mmPM)
  Date: June 12 96 00::00:00 (month dd yy hh:mm::ss)

If time is not passed then time defaults to 00:00:00.

=cut
sub str2time {
	my $self	= shift;
	my $string	= shift;

	Date::Parse::str2time( $string );
} # END sub str2time


=item C<time2str> ( $format )

For compatibility for the older DateTime::Date modules.  Passes the 
$format to strftime.

=cut
sub time2str {
	my $self	= shift;
	my $f		= shift;
	$self->strftime( $f );
} # END of time2str


=item C<time_local> (  )

For compatibility for the older DateTime::Date modules.  Returns $self->epoch.

=cut
sub time_local { $_[0]->epoch }


=item C<month_full> (  )

Returns the full month string based on the integer month.

=item C<month_full2abrv> (  )

Returns the abbreviated (3 char) month string based on the full month name.

=cut
sub month_full			{ return $_[0]->months_full_list->[ $_[0]->_mon ]	}
sub month_full2abrv		{ return $_[0]->month_abrv->{ $_[0]->month_full }	}


=item C<months_list> (  )

Returns an array ref of abbreviated months.

=cut
sub months_list {
	return [ @Date::Language::English::MoYs ];
} # END of months_list


=item C<months_full_list> (  )

Returns an array ref of months.

=cut
sub months_full_list {
	return [ @Date::Language::English::MoY ];
} # END of months_full_list


=item C<months> (  )

Returns a hash ref of abbreviated months.  With the keys being the true month 
value (1 .. 12).

=item C<months_full> (  )

Returns a hash ref of full month names.  With the keys being the true month 
value (1 .. 12).

=item C<month_abrv> (  )

Returns a hash ref of abbreviated months.  With the keys being the full month name.

=cut
sub months				{ return { map { $_ => $_[0]->months_list->[$_ - 1] }							(1 .. @{ $_[0]->months_list }) } }
sub months_pad			{ return { map { sprintf("%02d", $_) => $_[0]->months_list->[$_ - 1] }			(1 .. @{ $_[0]->months_list }) } }
sub months_full			{ return { map { $_ => $_[0]->months_full_list->[$_ - 1] }						(1 .. @{ $_[0]->months_full_list }) } }
sub months_full_pad		{ return { map { sprintf("%02d", $_) => $_[0]->months_full_list->[$_ - 1] }		(1 .. @{ $_[0]->months_full_list }) } }
sub month_abrv			{ return { map { $_[0]->months_full_list->[$_] => $_[0]->months_list->[$_] }	(0 .. 11) } }


=item C<int_months> (  )

Returns a hash ref of abbreviated months.  With the keys being the integer month 
value (0 .. 12).

=item C<int_months_full> (  )

Returns a hash ref of full month names.  With the keys being the integer month 
value (0 .. 12).

=cut
sub int_months		{ return { map { $_ => $_[0]->months_list->[$_] }			(0 .. $#{ $_[0]->months_list } ) } }
sub int_months_full	{ return { map { $_ => $_[0]->months_full_list->[$_] }		(0 .. $#{ $_[0]->months_full_list } ) } }


=item C<last_day> ( [ $mon ] [, $year ] )

Returns the last day of the of the month and year passed.  If nothing is passed 
then it uses the objects month and year.  Month is the integer month 0 .. 11, and 
year is the 4 digit year.

=cut
sub last_day {
	my $self	= shift;
	my $mon		= shift;
	my $year	= shift;

	$mon	= $self->mon unless (defined $mon);
	$year	= $self->year unless (defined $year);

	return $self->last_days->{ $mon } unless ($mon == 1);
	return 28 unless $self->is_leap_year( $year );
	return 29;
} # END of last_day


=item C<last_days> (  )

Returns a hash ref of the last day for each month.  The keys are 
the integer months (0 .. 11).

=cut
sub last_days { return { 0 => '31', 1 => '28', 2 => '31', 3 => '30', 4 => '31', 5 => '30', 6 => '31', 7 => '31', 8 => '30', 9 => '31', 10 => '30', 11 => '31' } }


=item C<is_leap_year> (  )

Returns true if the year is a leap year.

=cut
sub is_leap_year	{
	my $self = shift;
	my $year = shift || $self->year;
	
	(($year % 4 == 0) && (($year % 100 != 0) || ($year % 400 == 0))) ? 1 : 0;
} # END of is_leap_year


=item C<hours24> (  )

Returns an array ref of hours in 24hr time.

=item C<hours> (  )

Returns an array ref of hours in 12hr time.  Padded with zeros.

=item C<minutes> (  )

Returns an array ref of minutes (0 .. 60).  Padded with zeros.

=cut
sub hours24	{ return [ '00','01','02','03','04','05','06','07','08','09', (10 .. 23) ] }
sub hours	{ return [ '01','02','03','04','05','06','07','08','09','10','11','12' ] }
sub minutes	{ return [ '00','01','02','03','04','05','06','07','08','09', (10 .. 59) ] }


# This is where we muck in someone else's namespace.  Not for the faint of heart mind you!
package Time::Object;

use overload 'fallback' => 1;

1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Time.pm,v $
 Revision 1.10  2000/12/12 18:54:34  useevil
  - updated version for new release:  1.92

 Revision 1.9  2000/11/15 19:38:50  useevil
  - added str2time()
  - fixed bug in new() where $time was always defined

 Revision 1.8  2000/10/17 00:49:04  dweimer
 Merged over thai's commit, comment below:

 - added time2str() and time_local() for former users of DateTime::Date

 Revision 1.7  2000/09/19 23:42:07  dweimer
 Version update 1.91

 Revision 1.6  2000/09/13 20:10:42  thai
  - added use Data::Language::English

 Revision 1.5  2000/09/13 18:17:21  david
 Data::Dumper only loaded if $debug is on.

 Revision 1.4  2000/09/08 05:18:53  thai
  - added:
      month_full()
      month_full2abrv()
  - updated the POD documentation

 Revision 1.3  2000/09/08 00:56:09  thai
  - fixed the POD errors per Smeg's request

 Revision 1.2  2000/09/07 22:27:32  thai
  - added:
      last_day()
      last_days()
      is_leap_year()

 Revision 1.1  2000/09/07 18:27:57  thai
  - has ousted DateTime::Date as the default date/time class
  - sub classes Time::Object


=head1 SEE ALSO

Time::Object, perl(1).

=head1 KNOWN BUGS

None

=head1 TODO

Nothing yet... anybody have suggestions?

=head1 COPYRIGHT

Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free 
software. It may be used, redistributed and/or modified under the terms 
of the GNU Lesser General Public License as published by the Free Software 
Foundation.

You should have received a copy of the GNU Lesser General Public License 
along with this library; if not, write to the Free Software Foundation, Inc., 
59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

 Thai Nguyen <thai@cnation.com>

=cut
