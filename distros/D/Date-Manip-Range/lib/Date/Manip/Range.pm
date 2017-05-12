=pod

=head1 NAME

Date::Manip::Range - Parses and holds a date range

=head1 SYNOPSIS

  use Date::Manip::Range;
  my $range = Date::Manip::Range->new();
  $range->parse( 'today through tomorrow' );
  $range->adjust( '3 days' );
  print $range->printf;

=head1 DESCRIPTION

B<Date::Manip::Range> parses and holds a date range. The range is defined by a 
start and end point. The module accepts ranges as a single string of two dates 
separated by a range operator. Some examples...

  my $range = Date::Manip::Range->new( {parse => 'today - tommorrow'} );
  my $range = Date::Manip::Range->new( {parse => 'Jan 21 through Feb 3'} );
  my $range = Date::Manip::Range->new( {parse => '2015-01-29 to 2015-02-03'} );
  my $range = Date::Manip::Range->new( {parse => 'from Jan 21 to Feb 3'} );
  my $range = Date::Manip::Range->new( {parse => 'between Jan 21 and Feb 3'} );

B<Date::Manip::Range> recognizes the following range operators...

=over

=item through

=item thru

=item to

=item -

=item ...

=item ..

=item between/and

=item and

=item from/through

=item from/thru

=item from/to

=back

B<Date::Manip::Range> splits the string on the operator, extracting the start
and end points. It creates L<Date::Manip> objects from those two points. The 
dates can be anything parsable by L<Date::Manip>.

=head2 Important Facts

=over

=item Date strings can be anything parsable by L<Date::Manip>.

=item Dates must be in the correct order.

=item Range operators are case insensetive.

=item Ranges do not support times. Ranges only work on whole days.

=back

=head2 Implicit Ranges

B<Date::Manip::Range> supports the concept of I<implicit ranges>. A range is 
implied when you pass a single time period into L</parse>. For example,
C<April 2015> implies the range 2015-04-01 through 2015-04-30. 
B<Date::Manip::Range> creates an implicit range when there is no range operator.

B<Date::Manip::Range> accepts these forms of implicit ranges...

=over

=item yyyy

Any four digit value translates into an entire year, from January 01 through 
December 31.

=item yyyy-mm

=item Month YYYY

=item mm/yyyy

Any two part value implies a one month range from the first to the last day.
For the month, you can use a number, 3 letter abbreviation, or spell out the
full name.

=back

=head2 Implicit Start and End Dates

B<Date::Manip::Range> also recognizes implied start and end dates. This is 
where you give an implicit range as both the start and end, like these...

  January through March
  April 2015 - August 2015
  2014 to 2015

The start date falls on the first day of the implied range. That would be 
January 1 for years and the first day of the month for others.

The end date falls on the last day of the implied range. For years, that's
December 31. For months, it is the last day of the month. The code correctly
calculates the last day of the month - even for Februrary and leap years.

L</parse> sets the L</date_format> to the shortest implied range. For example, 
L</printf> converts C<2014 to May 2015> into C<January 2014 to May 2015>. And
C<April 2015 to May 15, 2015> becomes C<April 01, 2015 to May 15, 2015>.

=cut

package Date::Manip::Range;

use 5.14.0;
use warnings;

use Date::Manip;
use Moose;
use String::Util qw/hascontent trim/;


our $VERSION = '1.21';


=head1 METHODS & ATTRIBUTES

=head3 new

B<new> creates a new object. You may pass default values in a hash reference.
B<new> accepts the following...

=over 

=item parse

A date range in string form passed directly into the L</parse> method. This 
allows you to initialize the object in one statement instead of two. Check the 
L</is_valid> method and L<error> attribute for error messages.

=cut

sub BUILD {
	my ($self, $attributes) = @_;

	my $range = $attributes->{parse};
	$self->parse( $range ) if hascontent( $range );
}


=item include_start 

=item include_end

These attributes mark inclusive or exclusive ranges. By default, a range 
includes dates that fall on the start or end. For example...

  $range->new( {parse => '2015-01-15 to 2015-01-31'} );
  # returns true because the start is included
  $range->includes( '2015-01-15' );
  # retruns true because it is between the start and end
  $range->includes( '2015-01-20' );
  # retruns true because the end is included
  $range->includes( '2015-01-31' );

For exclusive ranges, set one or both of these values to B<false>.

  $range->new( {parse => '2015-01-15 to 2015-01-31'} );
  $range->include_start( 0 );
  # returns false because the start is excluded
  $range->includes( '2015-01-15' );
  # retruns true because it is between the start and end
  $range->includes( '2015-01-20' );
  # retruns true because the end is included
  $range->includes( '2015-01-31' );

=cut

has 'include_start' => (
	default => 1,
	is      => 'rw',
	isa     => 'Bool',
);

has 'include_end' => (
	default => 1,
	is      => 'rw',
	isa     => 'Bool',
);


=back

=head3 parse

This method takes a string, parses it, and configures the B<Date::Manip::Range>
object. C<parse> returns B<true> on success or B<false> for an error. Call
L</error> for a more specific error message.

  my $range = Date::Manip::Range->new();
  $range->parse( 'June 2014 through May 2015' );

=cut

sub parse {
	my ($self, $string) = @_;
	
	# Split the string into pieces around the operator.
	my $prefix = '';

	if ($string =~ m/^\s*(between|from)\s(.*)$/i) {
		$prefix = trim( $1 );
		$string = trim( $2 );
	}

	my ($first, $second, $operator) = ('', '', '');
	if ($string =~ m/^(.*)\s(-|and|through|thru|to)\s(.*)$/i) {
		$first    = trim( $1 );
		$operator = trim( $2 );
		$second   = trim( $3 );
	} elsif ($string =~ m/^(.*)(\.\.\.)(.*)$/i) {
		$first    = trim( $1 );
		$operator = trim( $2 );
		$second   = trim( $3 );
	} elsif ($string =~ m/^(.*)(\.\.)(.*)$/i) {
		$first    = trim( $1 );
		$operator = trim( $2 );
		$second   = trim( $3 );
	}

	# Set the format so that the printed range looks like the original.
	if ($prefix ne '' && $operator eq '') {
		$self->_error( 'Missing range operator' );
		return 0;
	} elsif ($operator eq '') {
		# Parse the implicit range using the first day as the start.
		my $granularity;
		($first, $granularity) = $self->_normalize( $string );

		my $date1 = Date::Manip::Date->new;
		if ($date1->parse( $first )) {
			$self->_error( "$string is not a valid date" );
			return 0;
		}

		# Set the start and end dates to the implicit range. 
		$self->_start( $date1 );
		$self->_end( $self->_add( $date1, $granularity, '-1 day' ) );
		$self->_granularity( $granularity );

		# Set the output format correctly for implied ranges.
		$self->format( "%s" );
		$self->_date_format_for( $granularity );
	} else {
		# Parse the first date in the range.
		my ($normal1, $range1) = $self->_normalize( $first );
		my $date1 = Date::Manip::Date->new;
		if ($date1->parse( $normal1 )) {
			$self->_error( "$first is not a valid date" );
			return 0;
		}

		# Parse the second date in the range.
		my ($normal2, $range2) = $self->_normalize( $second );
		my $date2 = $date1->new;
		if ($date2->parse( $normal2 )) {
			$self->_error( "$second is an invalid date" );
			return 0;
		}
		$date2 = $self->_add( $date2, $range2, '-1 day' );

		# Verify that the dates are in the correct order. Since I only accept
		# a string as input, it makes no sense to allow reverse order. That
		# would not read correctly in English.
		if ($date1->cmp( $date2 ) > 0) {
			$self->_error( 'Start date falls after the end date' );
			return 0;
		}

		# Now change the object, after we've checked everything.
		$self->_start( $date1 );
		$self->_end( $date2 );
		$self->_granularity( '' );

		# Set the output format correctly for implied ranges.
		if ($prefix eq '') {
			$self->format( "%s $operator %s" );
		} else {
			$self->format( "$prefix %s $operator %s" );
		}
		$self->_date_format_for( $range1, $range2 );
	}

	return 1;
}


=head3 adjust

This method moves both the start and end dates by the same amount of time. It
allows you to shift an entire range.

B<adjust> accepts a delta string suitable for L<Date::Manip::Delta>. In 
addition, it you can use the following frequencies as the delta...

=over

=item * annual

Add 1 year to both dates.

=item * monthly

Add 1 month to both dates.

=item * weekly

Add 1 week to both dates.

=item * daily

Add 1 day to both dates.

=back

B<adjust> returns a boolean flag indicating success. On failure, check L</error>
for a message.

  my $range = Date::Manip::Range( {parse => 'June 2014 to May 2015'} );
  # Add 2 months to the start and end dates.
  $range->adjust( '2 months' );
  # Displays "August 2014 to July 2015" - a two month shift.
  $range->printf();

=cut

sub adjust {
	my ($self, $adjustment) = @_;
	
	if (!defined( $adjustment )) {
		$self->_error( 'Delta string required' );
		return 0;
	}

	my $delta;
	if ($adjustment eq 'annual') {
		$delta = $self->start->new_delta( '1 year' );
	} elsif ($adjustment eq 'monthly') {
		$delta = $self->start->new_delta( '1 month' );
	} elsif ($adjustment eq 'weekly') {
		$delta = $self->start->new_delta( '1 week' );
	} elsif ($adjustment eq 'daily') {
		$delta = $self->start->new_delta( '1 day' );
	} else {
		$delta = $self->start->new_delta;
		if ($delta->parse( $adjustment )) {
			$self->_error( "$adjustment is an invalid delta" );
			return 0;
		}
	}
	
	# Change the start and end dates by the same amount. Implicit ranges remain
	# implicit. The code automatically adjusts the end date to the end of the
	# period (year or month).
	$self->_start( $self->start->calc( $delta ) );

	if ($self->is_implicit) {
		$self->_end( $self->_add( $self->start, $self->granularity, '-1 day' ) );
	} else { $self->_end( $self->end->calc( $delta ) ); }

	return 1;
}


=head3 printf

This method returns the date range as a single string. The L</format> attribute
defines the resulting string. The method formates each date (start and end) 
using the L</date_format> attribute. B<printf> then drops those formatted dates
into the string using L</format>.

B<printf> accepts two optional parameters. The first parameter overrides the
L</date_format> attribute. The second parameter overrides the L</format>
attribute.

  my $range = Date::Manip::Range( {parse => 'June 2014 to May 2015'} );
  # Displays "June 2014 to May 2015".
  print $range->printf();
  # Displays "06/2014 to 05/2015".
  print $range->printf( '%m/%Y' );
  # Displays "06/2014 - 05/2015".
  print $range->printf( '%m/%Y', '%s - %s' );
  # Displays "June 2014 through May 2015".
  print $range->printf( undef, '%s through %s' );

=cut

sub printf {
	my ($self, $date, $format) = @_;
	$date   //= $self->date_format;
	$format //= $self->format;
	
	no warnings;
	sprintf $format, 
		$self->start->printf( $date ), 
		$self->end->printf( $date )
	;
}


=head3 format

This attributes formats the output of the L</printf> method. It follows the same
rules as L<sprintf>. The format can have up to two placeholders: one for the 
start date and one for the end date.

Behind the scenes, the code actually calls L<sprintf>. The start is passed as 
the first argument and the end date as the second.

L</parse> sets B<format> based on the appearance of the original input string.
You can change B<format> after calling L</parse>.

  # Default format is "%s to %s".
  my $range = Date::Manip::Range( {parse => 'June 2014 to May 2015'} );
  # Customize the format of "printf". It doesn't have to be a valid range.
  $range->format( 'starting %s until ending %s' );
  # Displays "starting June 2014 until ending May 2015".
  $range->printf();

=cut

has 'format' => (
	default  => '%s to %s',
	init_arg => undef,
	is       => 'rw',
	isa      => 'Str',
);


=head3 date_format

This attribute formats the dates when you call the L</printf> method. It uses 
the directives defined in 
L<Date::Manip::Date|Date::Manip::Date/PRINTF-DIRECTIVES>. Both the start and 
end dates use the same format.

L</parse> sets B<date_format> based on the appearance of the original input 
string. You can change B<date_format> after calling L</parse>.

  # Default format is "%B %Y".
  my $range = Date::Manip::Range( {parse => 'June 2014 to May 2015'} );
  # Customize the dates for "printf".
  $range->date_format( '%m/%Y' );
  # Displays "06/2014 to 05/2015".
  $range->printf();

=cut

has 'date_format' => (
	default  => '%B %Y',
	init_arg => undef,
	is       => 'rw',
	isa      => 'Str',
);


=head3 includes

This method tells you if a given date falls within the range. A B<true> value
means that the date is inside of the range. B<false> says that the date falls
outside of the range.

The date can be a string or L<Date::Manip> object. Strings accept any valid
input for L<Date::Manip::Date>. If the date is invalid, C<includes> sets the 
L</error> attribute and returns B<false>.

Note that B<includes> does not tell you if the date comes before or after the 
range. That didn't seem relevant.

=cut

sub includes {
	my ($self, $check) = @_;

	# Parse the date parameter.
	my $date;
	if (ref( $check ) eq '') {
		$date = Date::Manip::Date->new;
		if ($date->parse( $check )) {
			$self->_error( "$check is not a valid date" );
			return 0;
		}
	} elsif (ref( $check ) eq 'Date::Manip::Date') {
		$date = $check;
	} else {
		$self->_error( "$check is not a valid date" );
		return 0;
	}

	# Compare the date with the start/end points.
	my $after_start = 0;
	if ($self->include_start) {
		$after_start = 1 if $date->cmp( $self->start ) >= 0;
	} else {
		$after_start = 1 if $date->cmp( $self->start ) > 0;
	}

	my $before_end = 0;
	if ($self->include_end) {
		$before_end = 1 if $date->cmp( $self->end ) <= 0;
	} else {
		$before_end = 1 if $date->cmp( $self->end ) < 0;
	}
	
	# Return the result.
	return ($after_start && $before_end ? 1 : 0);
}


=head3 is_valid

This method tells you if the object holds a valid date range. Use this after
calling the L</new> or L</parse> methods. If anything failed (invalid dates), 
C<is_valid> returns B<false>. 

  if (!$range->is_valid()) { 
    print $range->error; 
  }

=cut

sub is_valid {
	my ($self) = @_;

	return 0 if !defined( $self->start );
	return 0 if !defined( $self->end );
	return 0 if $self->error ne '';
	return 1;
}


=head3 error

Returns the last error message. This attribute can be set by the L</new>, 
L</parse>, L</adjust>, or L</includes> methods. An empty string indicates no 
problem. You should check this value after calling one of those methods.

The object automatically clears the error message with each call to L</parse>,
L</includes>, or </adjust>. That way previous errors do not make the changed
object invalid.

=cut

has 'error' => (
	default  => '',
	init_arg => undef,
	isa      => 'Str',
	reader   => 'error',
	writer   => '_error',
);

before qr/(adjust|parse|includes)/ => sub {
	my $self = shift;
	$self->_error( '' );
};


=head3 start / end

The L<Date::Manip::Date> objects representing the end points of the range. Note
that you cannot set B<start> or B<end>. Use the L</parse> or L</adjust> methods
instead.

=cut

has 'start' => (
	init_arg => undef,
	isa      => 'Date::Manip::Date',
	reader   => 'start',
	writer   => '_start',
);

has 'end' => (
	init_arg => undef,
	isa      => 'Date::Manip::Date',
	reader   => 'end',
	writer   => '_end',
);


=head3 is_implicit

This method signals if the object holds an implicit range. Implicit ranges
occur when passing a single date value into L</new> or L</parse>. 
B<is_implicit> returns B<true> if the range is implicit.

=cut

sub is_implicit {
	my ($self) = @_;
	
	return 1 if hascontent( $self->granularity );
	return 0;
}


=head3 granularity

B<granularity> defines the amount of time covered by an implicit range. It
has a value like C<1 year> or C<1 month> or C<1 day>. B<granularity> is a 
read-only attribute. It is set by the L</new> and L</parse> methods.

=cut

has 'granularity' => (
	default  => '',
	init_arg => undef,
	isa      => 'Str',
	reader   => 'granularity',
	writer   => '_granularity',
);


#-------------------------------------------------------------------------------
# Internal methods and attributes...

# This method adds a delta to a date. It accepts a list of deltas as strings.
# The code applies each delta in turn. It returns the final 
# L<Date::Manip::Date> object.
# 
# Pass the starting L<Date::Manip::Date> object followed by the delta strings.
# 
# I was constantly creating L<Date::Manip::Delta> objects for one-off 
# calculations. This saved me a lot of copy-and-pasting.

sub _add {
	my $self = shift;
	my $date = shift;
	
	foreach my $string (@_) {
		my $delta = $date->new_delta( $string );
		$date = $date->calc( $delta );
	}
	return $date;
}


# This method formats the date based on the input format. It chooses the 
# shortest implied range, copying the lowest level of detail from the input 
# string.

sub _date_format_for {
	my $self = shift;
	
	my $shortest = (sort @_)[0];

	if ($shortest =~ m/year/i)     { $self->date_format( '%Y'        ); }
	elsif ($shortest =~ m/month/i) { $self->date_format( '%B %Y'     ); } 
	else                           { $self->date_format( '%B %d, %Y' ); }
}


# This method normalizes a date string. It does the actual parsing of implied
# ranges. This code allows me to use strings like C<January to March> as a 
# valid date range. 
# 
# The method returns a list with two elements. The first element is a date
# string suitable for L<Date::Manip::Date>. The second is the L</granularity> 
# of the implicit range.

sub _normalize {
	my ($self, $string) = @_;
	my ($date, $granularity) = ('', '');
	
	my @pieces = split( /[-\s\/,]+/, trim( $string ) );
	if (scalar( @pieces ) == 0) {
		$self->_error( 'The dates are missing' );
	} elsif (scalar( @pieces ) == 1) {
		if ($string =~ m/^\d{4}$/) {
			$granularity = '1 year';
			$date = "$string-January-01";
		} else {
			$granularity = '1 month';
			$date = "$string-01";
		}
	} elsif (scalar( @pieces ) == 2) {
		if ($pieces[0] =~ m/^\d{4}$/) {
			$granularity = '1 month';
			$date = join '-', $pieces[0], $pieces[1], '01';
		} elsif ($pieces[1] =~ m/^\d{4}$/) {
			$granularity = '1 month';
			$date = join '-', $pieces[1], $pieces[0], '01';
		} else {
			$granularity = '1 day';
			$date = $string;
		}
	} else {
		$granularity = '1 day';
		$date = $string;
	}

	return ($date, $granularity);
}

#-------------------------------------------------------------------------------


=head1 BUGS/CAVEATS/etc

B<Date::Manip::Range> only supports English range operators. Translations 
welcome.

=head1 SEE ALSO

L<Date::Manip>

=head1 REPOSITORY

L<https://github.com/rbwohlfarth/Date-Manip-Range>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016  Robert Wohlfarth

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl 5.10.0. For more details, see the full text 
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but 
without any warranty; without even the implied

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
