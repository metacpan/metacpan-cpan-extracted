package Brick::Dates;
use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

use subs qw();

use Carp qw(carp croak);
use DateTime;

=encoding utf8

=head1 NAME

Brick - This is the description

=head1 SYNOPSIS

	use Brick;

=head1 DESCRIPTION


=over 4

=item _is_YYYYMMDD_date_format

=cut

sub _is_YYYYMMDD_date_format
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name => $setup->{name} || $caller[0]{'sub'},
		code => $bucket->_matches_regex( {
			description  => "The $setup->{field} is in the YYYYMMDD date format",
			field        => $setup->{field},
			name         => $caller[0]{'sub'},
			regex        => qr/
				\A
				\d\d\d\d   # year
				\d\d       # month
				\d\d       # day
				\z
				/x,
			} )
		} );
	}

sub _is_valid_date
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name => $setup->{name} || $caller[0]{'sub'},
		code => sub {
			my $eval_error = 'Could not parse YYYYMMMDD date';
			if( my( $year, $month, $day ) =
				$_[0]->{$setup->{field}} =~ m/(\d\d\d\d)(\d\d)(\d\d)/g )
				{
				$eval_error = '';
				my $dt = eval {
					DateTime->new(
						year  => $year,
						month => $month,
						day   => $day,
						) };

				return 1 unless $@;
				$eval_error = $@;
				}

			my $date_error = do {
				if( $eval_error =~ /^The 'month' parameter/ )
					{ 'The month is not right' }
				elsif( $eval_error =~ /^Invalid day of month/ )
					{ 'The day of the month is not right' }
				else
					{ 'Could not parse YYYYMMMDD date' }
				};

			die {
				message => "The value in $setup->{field} [$_[0]->{$setup->{field}}] was not a valid date: $date_error",
				failed_field => $setup->{field},
				handler => $caller[0]{'sub'},
				} if $eval_error;

			#	1;
				},
		} );

	}

=item _is_YYYYMMDD_date_format

=cut

=pod

sub _is_in_the_future
	{
	my( $bucket, $setup ) = @_;
	croak "Not implemented";
	}

sub _is_tomorrow
	{
	my( $bucket, $setup ) = @_;
	croak "Not implemented";
	}

sub _is_today
	{
	my( $bucket, $setup ) = @_;
	croak "Not implemented";
	}

sub _is_yesterday
	{
	my( $bucket, $setup ) = @_;
	croak "Not implemented";
	}

sub _is_in_the_past
	{
	my( $bucket, $setup ) = @_;
	croak "Not implemented";
	}

=cut

sub _date_is_after
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Date is after the start date",
		code        => sub {
			my $start   = $setup->{start_date} || $_[0]->{$setup->{start_date_field}};
			my $in_date = $setup->{input_date} || $_[0]->{$setup->{input_date_field}};

			#print STDERR "date after: $start --> $in_date\n";
			die {
				handler => $setup->{name} || $caller[0]{'sub'},
				message => "Date [$in_date] is not after start date [$start]",
				failed_field => $setup->{field},
				} if $in_date <= $start;
			1;
			},
		} );
	}

sub _date_is_before
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Date is before the end date",
		code        => sub {
			my $end     = $setup->{end_date}   || $_[0]->{$setup->{end_date_field}};
			my $in_date = $setup->{input_date} || $_[0]->{$setup->{input_date_field}};

			#print STDERR "date before: $in_date --> $end\n";
			die {
				handler => $setup->{name} || $caller[0]{'sub'},
				message => "Date [$in_date] is not before end date [$end]",
				failed_field => $setup->{field},

				} if $end <= $in_date;
			},
		} );
	}

=item date_within_range



=cut

sub date_within_range  # inclusive, negative numbers indicate past
	{
	my( $bucket, $setup ) = @_;

	my $before_sub = $bucket->_date_is_before( $setup );
	my $after_sub  = $bucket->_date_is_after( $setup );

	my $composed   = $bucket->__compose_satisfy_all( $after_sub, $before_sub );

	$bucket->__make_constraint( $composed, $setup );
	}

=item days_between_dates_within_range( HASHREF )

I can specify any of the dates as part of the setup by supplying them
as the values for these keys in the setup hash:

	start_date
	end_date
	input_date

Instead of fixed values, I can tell the function to get values from
input fields. Put the field names in the values for these keys of
the setup hash"

	start_date_field
	end_date_field
	input_date_field

I can use any combination of these setup fields, although the
start_date, end_date, and input_date take precedence.

TO DO: Need to validate all the date formats before I use them
in the comparisons

=cut

sub days_between_dates_within_range  # inclusive, negative numbers indicate past
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => $setup->{name} || $caller[0]{'sub'},
			description => "",
			code        => sub {
				my $start   = $setup->{start_date} || $_[0]->{$setup->{start_date_field}};
				my $end     = $setup->{end_date}   || $_[0]->{$setup->{end_date_field}};
				my $in_date = $setup->{input_date} || $_[0]->{$setup->{input_date_field}};

				die {
					message => 'Dates were not within range',
					handler => '',
					failed_field => $setup->{field},
					} unless $start <= $in_date && $in_date <= $end;
				}
			} )
		);
	}

=item days_between_dates_outside_range( HASHREF )

I can specify any of the dates as part of the setup by supplying them
as the values for these keys in the setup hash:

	start_date
	end_date
	input_date

Instead of fixed values, I can tell the function to get values from
input fields. Put the field names in the values for these keys of
the setup hash"

	start_date_field
	end_date_field
	input_date_field

I can use any combination of these setup fields, although the
start_date, end_date, and input_date take precedence.

TO DO: Need to validate all the date formats before I use them
in the comparisons

=cut

sub days_between_dates_outside_range
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => $setup->{name} || $caller[0]{'sub'},
			description => "",
			code        => sub {
				my $start   = $setup->{start_date} || $_[0]->{$setup->{start_date_field}};
				my $end     = $setup->{end_date}   || $_[0]->{$setup->{end_date_field}};
				my $in_date = $setup->{input_date} || $_[0]->{$setup->{input_date_field}};

				die {
					message => 'Dates were not outside range',
					handler => '',
					failed_field => $setup->{field},
					} unless $in_date < $start || $end < $in_date;
				}
			} )
		);
	}

=item at_least_N_days_between

=cut

sub at_least_N_days_between
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => $setup->{name} || $caller[0]{'sub'},
			description => "Dates within $setup->{number_of_days} days",
			code        => sub {
				my $start   = $setup->{start_date} || $_[0]->{$setup->{start_date_field}};
				my $end     = $setup->{end_date}   || $_[0]->{$setup->{end_date_field}};

				print STDERR "Expected interval: $setup->{number_of_days}\n" if $ENV{DEBUG};

				my $interval = $bucket->_get_days_between( $start, $end );
				print STDERR "Interval: $start --> $interval --> $end\n" if $ENV{DEBUG};

				die {
					message => 'Dates were not within range',
					handler => 'at_least_N_days_between',
					failed_field => $setup->{field},

					} unless $interval >= $setup->{number_of_days};
				}
			} )
		);
	}

=item at_most_N_days_between

Like C<at_least_N_days_between>, but the dates cannot be more than N days
apart.

At the moment this has the curious result that if the end date in before the
start date, the duration between them is negative, so that duration is shorter
than any positive number. This isn't a bug but a loack of a design decision
if I should require the end date to be after the start date.

=cut

sub at_most_N_days_between
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => $setup->{name} || $caller[0]{'sub'},
			description => "",
			code        => sub {
				my $start   = $setup->{start_date} || $_[0]->{$setup->{start_date_field}};
				my $end     = $setup->{end_date}   || $_[0]->{$setup->{end_date_field}};

				my $interval = $bucket->_get_days_between( $start, $end );
				print STDERR "Interval: $start --> $interval --> $end\n" if $ENV{DEBUG};

				die {
					message => 'Dates were outside the range',
					handler => 'at_most_N_days_between',
					failed_field => $setup->{field},

					} unless $setup->{number_of_days} >= $interval;
				}
			} )
		);
	}

=pod

sub at_most_N_days_after
	{
	my( $bucket, $setup ) = @_;

	croak "Not implemented!";
	}

sub at_most_N_days_before
	{
	my( $bucket, $setup ) = @_;

	croak "Not implemented!";
	}

sub before_fixed_date
	{
	my( $bucket, $setup ) = @_;

	croak "Not implemented!";
	}

sub after_fixed_date
	{
	my( $bucket, $setup ) = @_;

	croak "Not implemented!";
	}

=cut

# return negative values if second date is earlier than first date

=item __get_ymd_as_hashref( YYYYMMDD );

Given two dates in YYYYMMDD format, return the number of days between
them, including the last date.

For the dates 20070101 and 20070103, return 2 because it includes the
last day.

For the dates 20070101 and 20060101, return -365 because the last date
is in the past.

=cut

sub _get_days_between
	{
	my( $bucket, $start, $stop ) = @_;

	my @dates;

	foreach my $date ( $start, $stop )
		{
		my( $year, $month, $day ) = $bucket->__get_ymd_as_hashref( $date );

		push @dates, DateTime->new(
			$bucket->__get_ymd_as_hashref( $date )
			);
		}

	my $duration = $dates[1]->delta_days( $dates[0] );

	$duration *= -1 if $dates[1] < $dates[0];

	my $days = $duration->delta_days;
	}

=item __get_ymd_as_hashref( YYYYMMDD );

Given a date in YYYYMMDD format, return an anonymous hash with the
keys:

	year
	month
	day

=cut

sub __get_ymd_as_hashref
	{
	my( $bucket, $date ) = @_;

	my %hash = eval {
		die "Could not parse date!"
			unless $date =~ m/
			\A
			(\d\d\d\d)
			(\d\d)
			(\d\d)
			\z
			/x;

		my $dt = DateTime->new( year => $1, month => $2, day => $3 );

		map { $_, $dt->$_ } qw( year month day );
		};

	if( $@ )
		{
		$@ =~ s/\s+at\s+$0.*//s;
		croak( "$@: I got [$date] but was expecting something in YYYYMMDD format!" );
		}

	\%hash;
	}


=back

=head1 TO DO

TBA

=head1 SEE ALSO

TBA

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
