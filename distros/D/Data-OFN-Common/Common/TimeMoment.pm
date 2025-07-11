package Data::OFN::Common::TimeMoment;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.08 qw(check_bool check_isa);

our $VERSION = 0.02;

has date => (
	is => 'ro',
);

has date_and_time => (
	is => 'ro',
);

has flag_unspecified => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check date.
	check_isa($self, 'date', 'DateTime');
	if (defined $self->{'date'}) {
		if ($self->date->hour != '0') {
			err "Parameter 'date' must have a hour value of zero.";
		}
		if ($self->date->minute != '0') {
			err "Parameter 'date' must have a minute value of zero.";
		}
		if ($self->date->second != '0') {
			err "Parameter 'date' must have a second value of zero.";
		}
	}

	# Check date_and_time.
	check_isa($self, 'date_and_time', 'DateTime');
	if (defined $self->date_and_time
		&& $self->date_and_time->hour == 0
		&& $self->date_and_time->minute == 0
		&& $self->date_and_time->second == 0) {

		err "Parameter 'date_and_time' should be a 'date' parameter.";
	}

	if (defined $self->date && defined $self->date_and_time) {
		err "Parameters 'date' and 'date_and_time' could not be defined together.";
	}

	# Check flag_unspecified.
	if (! defined $self->{'flag_unspecified'}) {
		$self->{'flag_unspecified'} = 0;
	}
	check_bool($self, 'flag_unspecified');

	if (defined $self->date && $self->{'flag_unspecified'}) {
		err "Parmaeter 'date' and 'flag_unspecified' could not be defined together.";
	}
	if (defined $self->date_and_time && $self->{'flag_unspecified'}) {
		err "Parmaeter 'date_and_time' and 'flag_unspecified' could not be defined together.";
	}
	if (! $self->flag_unspecified
		&& ! defined $self->date
		&& ! defined $self->date_and_time) {

		err "Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::OFN::Common::TimeMoment - OFN common data object for time moment.

=head1 SYNOPSIS

 use Data::OFN::Common::TimeMoment;

 my $obj = Data::OFN::Common::TimeMoment->new(%params);
 my $date = $obj->date;
 my $date_and_time = $obj->date_and_time;
 my $flag_unspecified = $obj->flag_unspecified;

=head1 DESCRIPTION

Immutable data object for OFN (Otevřené formální normy) representation of
time moment in the Czech Republic.

This object is actual with L<2020-07-01|https://ofn.gov.cz/z%C3%A1kladn%C3%AD-datov%C3%A9-typy/2020-07-01/#%C4%8Dasov%C3%BD-okam%C5%BEik>
version of OFN basic data types standard.

=head1 METHODS

=head2 C<new>

 my $obj = Data::OFN::Common::TimeMoment->new(%params);

Constructor.

=over 8

=item * C<date>

Date object defined by DataTime.

It's optional.

Default value is undef.

=item * C<date_and_time>

Date and time object defined by DataTime.

It's optional.

Default value is undef.

=item * C<flag_unspecified>

Flag for definition that date isn't defined.

It's required.

Default value is 0.

=back

Returns instance of object.

=head2 C<date>

 my $date = $obj->date;

Get date.

Returns L<DateTime> instance.

=head2 C<date_and_time>

 my $date_and_time = $obj->date_and_time;

Get date and time

Returns L<DateTime> instance.

=head2 C<flag_unspecified>

 my $flag_unspecified = $obj->flag_unspecified;

Get flag for unspecified date.

Returns bool value (0/1).

=head1 ERRORS

 new():
         From Mo::utils::check_bool():
                 Parameter 'flag_unspecified' must be a bool (0/1).
                         Value: %s
         From Mo::utils::check_isa():
                 Parameter 'date' must be a 'DataTime' object.
                         Value: %s
                         Reference: %s
                 Parameter 'date_and_time' must be a 'DataTime' object.
                         Value: %s
                         Reference: %s
         Parmaeter 'date' and 'flag_unspecified' could not be defined together.
         Parameter 'date' must have a hour value of zero.
         Parameter 'date' must have a minute value of zero.
         Parameter 'date' must have a second value of zero.
         Parmaeter 'date_and_time' and 'flag_unspecified' could not be defined together.
         Parameter 'date_and_time' should be a 'date' parameter.
         Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters.
         Parameters 'date' and 'date_and_time' could not be defined together.

=head1 EXAMPLE1

=for comment filename=time_moment_date.pl

 use strict;
 use warnings;

 use Data::OFN::Common::TimeMoment;
 use DateTime;

 my $obj = Data::OFN::Common::TimeMoment->new(
         'date' => DateTime->new(
                 'day' => 8,
                 'month' => 7,
                 'year' => 2025,
         ),
 );

 print 'Date: '.$obj->date."\n";

 # Output:
 # Date: 2025-07-08T00:00:00

=head1 EXAMPLE2

=for comment filename=time_moment_date_and_time.pl

 use strict;
 use warnings;

 use Data::OFN::Common::TimeMoment;
 use DateTime;

 my $obj = Data::OFN::Common::TimeMoment->new(
         'date_and_time' => DateTime->new(
                 'day' => 8,
                 'month' => 7,
                 'year' => 2025,
                 'hour' => 12,
                 'minute' => 10,
         ),
 );

 print 'Date and time: '.$obj->date_and_time."\n";

 # Output:
 # Date and time: 2025-07-08T12:10:00

=head1 DEPENDENCIES

L<Error::Pure>
L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-OFN-Common>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
