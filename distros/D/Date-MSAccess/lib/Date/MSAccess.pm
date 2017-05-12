package Date::MSAccess;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 2003 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;

use Date::Calc qw(Days_in_Year Delta_Days leap_year);

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Date::MSAccess ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.05';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}

}	# End of encapsulated class data.

# -----------------------------------------------
# 37622 is 2003-01-01 12:00:00.

sub decode_date
{
	my($self, $date)	= @_;
	$date				-= 1;
	my($year)			= 1900;
	my($days_per_year)	= 0;

	while ($date > $days_per_year)
	{
		$days_per_year = Days_in_Year($year + 1, 12);

		if ($date > $days_per_year)
		{
			$year++;

			$date -= $days_per_year;
		}
	}

	my(@days_per_month)	= (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	$days_per_month[2]	= 29 if (leap_year($year) );
	my(@month_name)		= ('', 'Jan', 'Feb', 'Mar', 'May', 'Apr', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	my($month)			= 1;
	my($days_per_month)	= $days_per_month[$month];
	my($day)			= int($date);

	while ($day > $days_per_month)
	{
		$days_per_month = $days_per_month[$month];

		if ($day > $days_per_month)
		{
			$month++;

			$day -= $days_per_month;
		}
	}

	$month	= "0$month"	if (length($month) == 1);
	$day	= "0$day"	if (length($day) == 1);

	# One last check...

	( ($year > 1980) && ($year < 2038) && ($month >= '01') && ($month <= '12') && ($day >= '01') && ($day <= '31') ) ? "$year$month$day" : '00000000';

}	# End of decode_date.

# -----------------------------------------------

sub new
{
	my($caller, %arg)		= @_;
	my($caller_is_obj)		= ref($caller);
	my($class)				= $caller_is_obj || $caller;
	my($self)				= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		elsif ($caller_is_obj)
		{
			$$self{$attr_name} = $$caller{$attr_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	return $self;

}	# End of new.

# -----------------------------------------------

sub todays_date
{
	my($self)		= @_;
	my(@now_time)	= localtime();
	my($now_year)	= $now_time[5] + 1900;
	my($now_month)	= $now_time[4] + 1;
	my($now_day)	= $now_time[3];
	my($then_year)	= 2003;
	my($then_month)	= 1;
	my($then_day)	= 1;
	my($delta)		= Delta_Days($then_year, $then_month, $then_day, $now_year, $now_month, $now_day);

	$delta + 37622; # + 2003-01-01 in MS Access.

}	# End of todays_date.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<Date::MSAccess> - Manage dates in MS Access format

=head1 Synopsis

	use Date::MSAccess;

	my($obj)  = Date::MSAccess -> new();
	my($date) = $obj -> decode_date(37988); # Returns '20040101'.
	my($now)  = $obj -> todays_date();      # Returns 38006 on 20-Jan-2004.

=head1 Description

C<Date::MSAccess> is a pure Perl module.

It can convert a number which is an MS Access date into a string of the form 'YYYYMMDD'.

Also, it can return today's date in MS Access format.

Note: MS Access dates are based on 12 noon.

Note: MS Access dates can be fractional, eg 3008.25, but this module currently ignores such fractions.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Date::MSAccess> object.

This is the class's contructor.

Usage: Date::MSAccess -> new().

This option does not take any values.

=head1 Method: decode_date(<A number corresponding to an MS Access date>)

Either returns a string of the form 'YYYYMMDD', or the string '00000000'.

The latter was chosen to be compatible with MySQL and Postgres 'timestamp' fields.

eg: decode_date(37988) returns '20040101'.

=head1 Method: todays_date()

Returns a number corresponding to today's date in MS Access format.

Eg: On 20-Jan-2004 the number returned was 38006.

=head1 Reference

http://msdn.microsoft.com/library/default.asp?url=/archive/en-us/dnaraccgen/html/msdn_datetime.asp

=head1 Author

C<Date::MSAccess> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
