use strict;
use warnings;
package Date::Tiny;
# ABSTRACT: A date object, with as little code as possible

our $VERSION = '1.07';

use overload 'bool' => sub () { 1 };
use overload '""'   => 'as_string';
use overload 'eq'   => sub { "$_[0]" eq "$_[1]" };
use overload 'ne'   => sub { "$_[0]" ne "$_[1]" };





#####################################################################
# Constructor and Accessors

#pod =pod
#pod
#pod =method new
#pod
#pod   my $date = Date::Tiny->new(
#pod       year  => 2006,
#pod       month => 12,
#pod       day   => 31,
#pod       );
#pod
#pod The C<new> constructor creates a new B<Date::Tiny> object.
#pod
#pod It takes three named parameters. C<day> should be the day of the month (1-31),
#pod C<month> should be the month of the year (1-12), C<year> as a 4 digit year.
#pod
#pod These are the only parameters accepted.
#pod
#pod Returns a new B<Date::Tiny> object.
#pod
#pod =cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

#pod =pod
#pod
#pod =method now
#pod
#pod   my $current_date = Date::Tiny->now;
#pod
#pod The C<now> method creates a new date object for the current date.
#pod
#pod The date created will be based on localtime, despite the fact that
#pod the date is created in the floating time zone.
#pod
#pod Returns a new B<Date::Tiny> object.
#pod
#pod =cut

sub now {
	my @t = localtime time;
	shift->new(
		year  => $t[5] + 1900,
		month => $t[4] + 1,
		day   => $t[3],
	);
}

#pod =pod
#pod
#pod =method year
#pod
#pod The C<year> accessor returns the 4-digit year for the date.
#pod
#pod =cut

sub year {
	$_[0]->{year};
}

#pod =pod
#pod
#pod =method month
#pod
#pod The C<month> accessor returns the 1-12 month of the year for the date.
#pod
#pod =cut

sub month {
	$_[0]->{month};
}

#pod =pod
#pod
#pod =method day
#pod
#pod The C<day> accessor returns the 1-31 day of the month for the date.
#pod
#pod =cut

sub day {
	$_[0]->{day};
}

#pod =pod
#pod
#pod =method ymd
#pod
#pod The C<ymd> method returns the most common and accurate stringified date
#pod format, which returns in the form "2006-04-12".
#pod
#pod =cut

sub ymd {
	sprintf( "%04u-%02u-%02u",
		$_[0]->year,
		$_[0]->month,
		$_[0]->day,
	);
}





#####################################################################
# Type Conversion

#pod =pod
#pod
#pod =method as_string
#pod
#pod The C<as_string> method converts the date to the default string, which
#pod at present is the same as that returned by the C<ymd> method above.
#pod
#pod This string matches the ISO 8601 standard for the encoding of a date as
#pod a string.
#pod
#pod =cut

sub as_string {
	$_[0]->ymd;
}

#pod =pod
#pod
#pod =method from_string
#pod
#pod The C<from_string> method creates a new B<Date::Tiny> object from a string.
#pod
#pod The string is expected to be a "yyyy-mm-dd" ISO 8601 time string.
#pod
#pod   my $almost_christmas = Date::Tiny->from_string( '2006-12-23' );
#pod
#pod Returns a new B<Date::Tiny> object, or throws an exception on error.
#pod
#pod =cut

sub from_string {
	my $string = $_[1];
	unless ( defined $string and ! ref $string ) {
		require Carp;
		Carp::croak("Did not provide a string to from_string");
	}
	unless ( $string =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/ ) {
		require Carp;
		Carp::croak("Invalid time format (does not match ISO 8601 yyyy-mm-dd)");
	}
	$_[0]->new(
		year  => $1 + 0,
		month => $2 + 0,
		day   => $3 + 0,
	);
}

#pod =pod
#pod
#pod =method DateTime
#pod
#pod The C<DateTime> method is used to create a L<DateTime> object
#pod that is equivalent to the B<Date::Tiny> object, for use in
#pod conversions and calculations.
#pod
#pod As mentioned earlier, the object will be set to the 'C' locate,
#pod and the 'floating' time zone.
#pod
#pod If installed, the L<DateTime> module will be loaded automatically.
#pod
#pod Returns a L<DateTime> object, or throws an exception if L<DateTime>
#pod is not installed on the current host.
#pod
#pod =cut

sub DateTime {
	require DateTime;
	my $self = shift;
	DateTime->new(
		day       => $self->day,
		month     => $self->month,
		year      => $self->year,
		locale    => 'C',
		time_zone => 'floating',
		@_,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Tiny - A date object, with as little code as possible

=head1 VERSION

version 1.07

=head1 SYNOPSIS

  # Create a date manually
  $christmas = Date::Tiny->new(
      year  => 2006,
      month => 12,
      day   => 25,
      );
  
  # Show the current date
  $today = Date::Tiny->now;
  print "Year : " . $today->year  . "\n";
  print "Month: " . $today->month . "\n";
  print "Day  : " . $today->day   . "\n"; 

=head1 DESCRIPTION

B<Date::Tiny> is a member of the L<DateTime::Tiny> suite of time modules.

It implements an extremely lightweight object that represents a date,
without any time data.

=head2 The Tiny Mandate

Many CPAN modules which provide the best implementation of a concept
can be very large. For some reason, this generally seems to be about
3 megabyte of ram usage to load the module.

For a lot of the situations in which these large and comprehensive
implementations exist, some people will only need a small fraction of the
functionality, or only need this functionality in an ancillary role.

The aim of the Tiny modules is to implement an alternative to the large
module that implements a subset of the functionality, using as little
code as possible.

Typically, this means a module that implements between 50% and 80% of
the features of the larger module, but using only 100 kilobytes of code,
which is about 1/30th of the larger module.

=head2 The Concept of Tiny Date and Time

Due to the inherent complexity, Date and Time is intrinsically very
difficult to implement properly.

The arguably B<only> module to implement it completely correct is
L<DateTime>. However, to implement it properly L<DateTime> is quite slow
and requires 3-4 megabytes of memory to load.

The challenge in implementing a Tiny equivalent to DateTime is to do so
without making the functionality critically flawed, and to carefully
select the subset of functionality to implement.

If you look at where the main complexity and cost exists, you will find
that it is relatively cheap to represent a date or time as an object,
but much much more expensive to modify or convert the object.

As a result, B<Date::Tiny> provides the functionality required to
represent a date as an object, to stringify the date and to parse it
back in, but does B<not> allow you to modify the dates.

The purpose of this is to allow for date object representations in
situations like log parsing and fast real-time work.

The problem with this is that having no ability to modify date limits
the usefulness greatly.

To make up for this, B<if> you have L<DateTime> installed, any
B<Date::Tiny> module can be inflated into the equivalent L<DateTime>
as needing, loading L<DateTime> on the fly if necessary.

For the purposes of date/time logic, all B<Date::Tiny> objects exist
in the "C" locale, and the "floating" time zone (although obviously in a
pure date context, the time zone largely doesn't matter).

When converting up to full L<DateTime> objects, these local and time
zone settings will be applied (although an ability is provided to
override this).

In addition, the implementation is strictly correct and is intended to
be very easily to sub-class for specific purposes of your own.

=head1 USAGE

In general, the intent is that the API be as close as possible to the
API for L<DateTime>. Except, of course, that this module implements
less of it.

=head1 METHODS

=head2 new

  my $date = Date::Tiny->new(
      year  => 2006,
      month => 12,
      day   => 31,
      );

The C<new> constructor creates a new B<Date::Tiny> object.

It takes three named parameters. C<day> should be the day of the month (1-31),
C<month> should be the month of the year (1-12), C<year> as a 4 digit year.

These are the only parameters accepted.

Returns a new B<Date::Tiny> object.

=head2 now

  my $current_date = Date::Tiny->now;

The C<now> method creates a new date object for the current date.

The date created will be based on localtime, despite the fact that
the date is created in the floating time zone.

Returns a new B<Date::Tiny> object.

=head2 year

The C<year> accessor returns the 4-digit year for the date.

=head2 month

The C<month> accessor returns the 1-12 month of the year for the date.

=head2 day

The C<day> accessor returns the 1-31 day of the month for the date.

=head2 ymd

The C<ymd> method returns the most common and accurate stringified date
format, which returns in the form "2006-04-12".

=head2 as_string

The C<as_string> method converts the date to the default string, which
at present is the same as that returned by the C<ymd> method above.

This string matches the ISO 8601 standard for the encoding of a date as
a string.

=head2 from_string

The C<from_string> method creates a new B<Date::Tiny> object from a string.

The string is expected to be a "yyyy-mm-dd" ISO 8601 time string.

  my $almost_christmas = Date::Tiny->from_string( '2006-12-23' );

Returns a new B<Date::Tiny> object, or throws an exception on error.

=head2 DateTime

The C<DateTime> method is used to create a L<DateTime> object
that is equivalent to the B<Date::Tiny> object, for use in
conversions and calculations.

As mentioned earlier, the object will be set to the 'C' locate,
and the 'floating' time zone.

If installed, the L<DateTime> module will be loaded automatically.

Returns a L<DateTime> object, or throws an exception if L<DateTime>
is not installed on the current host.

=head1 HISTORY

This module was written by Adam Kennedy in 2006.  In 2016, David Golden
adopted it as a caretaker maintainer.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Tiny>, L<Time::Tiny>, L<Config::Tiny>, L<ali.as>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Date-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Date-Tiny>

  git clone https://github.com/dagolden/Date-Tiny.git

=head1 AUTHORS

=over 4

=item *

Adam Kennedy <adamk@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
