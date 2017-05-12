package DateTimeX::Format;
use Moose::Role;

use strict;
use warnings;

use DateTime;
use DateTime::Locale;
use DateTime::TimeZone;
use MooseX::Types::DateTime::ButMaintained qw/TimeZone Locale/;
use Carp;

use namespace::clean -except => 'meta';

requires 'parse_datetime';
requires 'format_datetime';

our $VERSION = '1.04';

has 'locale' => (
	isa         => Locale
	, is        => 'rw'
	, coerce    => 1
	, predicate => 'has_locale'
);

has 'time_zone' => (
	isa         => TimeZone
	, is        => 'rw'
	, coerce    => 1
	, predicate => 'has_time_zone'
);
has 'defaults' => ( isa => 'Bool', is => 'ro', default => 1 );
has 'debug' => ( isa => 'Bool', is => 'ro', default => 0 );

around 'parse_datetime' => sub {
	my ( $sub, $self, $time, $override, @args ) = @_;

	## Set Timezone: from args, then from object
	my $time_zone;
	if ( defined $override->{time_zone} ) {
		$time_zone = to_TimeZone( $override->{time_zone} );
	}
	elsif ( $self->has_time_zone ) {
		$time_zone = $self->time_zone;
	}
	elsif ( $self->defaults ) {
		carp "No time_zone supplied to constructor or the call to parse_datetime -- defaulting to floating\n"
			if $self->debug
		;
		$time_zone = DateTime::TimeZone->new( name => 'floating' );
	}
	else {
		carp "No time_zone supplied instructed to not use defaults"
	}


	## Set Locale: from args, then from object, then guess en_US
	my $locale;
	if ( defined $override->{locale} ) {
		$locale = to_Locale( $override->{locale} );
	}
	elsif ( $self->has_locale ) {
		$locale = $self->locale
	}
	elsif ( $self->defaults ) {
		carp "No locale supplied to constructor or the call to parse_datetime -- defaulting to en_US\n"
			if $self->debug
		;
		$locale = DateTime::Locale->load( 'en_US' );
	}
	else {
		carp "No time_zone supplied instructed to not use defaults"
	}

	my $env = {
		time_zone  => $time_zone
		, locale   => $locale
		, override => $override ## A copy of the original hash
	};
	
	## Calls the sub ( time, env, addtl args )
	my $dt = $self->$sub( $time , $env , @args );

	warn "Module did not return DateTime object"
		if ! blessed $dt eq 'DateTime'
		&& $self->debug
	;

	$dt;
	
};

sub new_datetime {
	my ( $self, $args ) = @_;

	if ( $self->debug ) {
		carp "Year Month and Day should be specified if Year Month or Day is specified\n"
			if ( defined $args->{day} || defined $args->{month} || defined $args->{year} )
			&& ( ! defined $args->{day} or ! defined $args->{month} or ! defined $args->{year} )
		;
		carp "Marking Year Month and Day as a default\n"
			if not (defined $args->{day} || defined $args->{months} || defined $args->{year})
		;
	}

	DateTime->new(
		time_zone => $args->{time_zone}
		, locale  => $args->{locale}

		, nanosecond  => ( defined ( $args->{nanosecond} ) ? $args->{nanosecond} : 0 )
		, second      => ( defined ( $args->{second} ) ? $args->{second} : 0 )
		, minute      => ( defined ( $args->{minute} ) ? $args->{minute} : 0 )
		, hour        => ( defined ( $args->{hour} ) ? $args->{hour} : 0 )

		, day     => ( defined( $args->{day} ) ? $args->{day} : 1 )
		, month   => ( defined( $args->{month} ) ? $args->{month} : 1 )
		, year    => ( defined( $args->{year} ) ? $args->{year} : 1 )
	);

}

1;

__END__

=head1 NAME

DateTimeX::Format - Moose Roles for building next generation DateTime formats

=head1 SYNOPSIS

	package DateTimeX::Format::Bleh;
	use Moose;
	with 'DateTimeX::Format';

	sub parse_datetime {
		my ( $self, $time, $env, @args ) = @_;
	}

	sub format_datetime {
		my ( $self, @args ) = @_;
	}

	my $dtxf = DateTimeX::Format::Bleh->new({
		locale       => $locale
		, time_zone  => $time_zone
		, debug      => 0|1
		, defaults   => 0|1
	});

	$dtxf->debug(0);
	$dtxf->time_zone( $time_zone );
	$dtxf->locale( $locale );
	$dtxf->defaults(1);

	my $dt = $dtxf->parse_datetime( $time, {locale=>$locale_for_call} );

	my $env = {
		time_zone  => $time_zone_for_call
		, locale  => $locale_for_call
	};
	my $dt = $dtxf->parse_datetime( $time, $env, @additional_arguments );
	my $dt = $dtxf->parse_datetime( $time, {time_zone=>$time_zone_for_call} )
	
	## if your module requires a pattern, or has variable time-input formats
	## see the Moose::Role DateTimeX::Format::CustomPattern
	package DateTimeX::Format::Strptime;
	use Moose;
	with 'DateTimeX::Format::CustomPattern';
	with 'DateTimeX::Format';


=head1 DESCRIPTION

This L<Moose::Role> provides an environment at instantation which can be overriden in the call to L<parse_data> by supplying a hash of the environment.

All of the DateTime based methods, locale and time_zone, coerce in accordence to what the docs of L<MooseX::Types::DateTime::ButMaintained> say -- the coercions apply to both runtime calls and constructors.

In addition this module provides two other accessors to assist in the development of modules in the L<DateTimeX::Format> namespace, these are C<debug>, and C<defaults>.

=head1 OBJECT ENVIRONMENT

All of these slots correspond to your object environment: they can be supplied in the constructor, or through accessors.

=over 4

=item * locale

Can be overridden in the call to ->parse_datetime.

See the docs at L<MooseX::Types::DateTime::ButMaintained> for informations about the coercions.

=item * time_zone

Can be overridden in the call to ->parse_datetime.

See the docs at L<MooseX::Types::DateTime::ButMaintained> for informations about the coercions.

=item * debug( 1 | 0* )

Set to one to get debugging information

=item * defaults( 1* | 0 )

Set to 0 to force data to be sent to the module

=back

=head1 HELPER FUNCTIONS

=over 4

=item new_datetime( $hashRef )

Takes a hashRef of the name value pairs to hand off to DateTime->new

=back

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetimex-format at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTimeX-Format>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc DateTimeX::Format

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTimeX-Format>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTimeX-Format>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTimeX-Format>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTimeX-Format/>

=back

=head1 ACKNOWLEDGEMENTS

Dave Rolsky -- provided some assistance with how DateTime works.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Evan Carroll, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
