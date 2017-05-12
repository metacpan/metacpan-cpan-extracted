package Business::CyberSource::Report;

use strict;
use warnings;

use Carp;
use Class::Load qw();
use Storable qw();


=head1 NAME

Business::CyberSource::Report - Factory class for modules that retrieve CyberSource's XML reports.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';

our $LOADED_REPORT_MODULES;


=head1 SYNOPSIS

	use Business::CyberSource::Report;
	use Business::CyberSource::Report::Test;

	# Generate a report factory.
	my $report_factory = Business::CyberSource::Report->new(
		merchant_id           => $merchant_id,
		username              => $username,
		password              => $password,
		use_production_system => $use_production_system,
	);

	# Use the factory to get a Business::CyberSource::Report::Test object with
	# the correct connection parameters.
	my $test_report = $report_factory->build( 'test' );

	# Retrieve a list of the report modules that have been loaded in memory,
	# either via "use" or a require by build()
	my $available_reports = $report_factory->list_loaded();

=head1 METHODS

=head2 new()

Create a new Business::CyberSource::Report factory object.

	my $report_factory = Business::CyberSource::Report->new(
		merchant_id           => $merchant_id,
		username              => $username,
		password              => $password,
		use_production_system => $use_production_system,
	);

Parameters:

=over

=item *

merchant_id: a merchant ID provided by CyberSource.

=item *

username/password: login access information you can create in
CyberSource's B<production> Business Center. The access will be automatically
available then in the test Business Center. Don't forget to give that user
reporting permissions.

=item *

use_production_system: whether queries should be sent to the production
system (1) or the test system (0). Off by default.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Check for required arguments.
	foreach my $arg ( qw( merchant_id password ) )
	{
		croak "The parameter >$arg< is missing"
			if !defined( $args{ $arg } ) || ( $args{ $arg } eq '' );
	}

	# By default per CyberSource's interface, the username is the merchant ID.
	$args{'username'} = $args{'merchant_id'}
		unless defined( $args{'username'} );

	# By default, use the test environment.
	$args{'use_production_system'} = 0
		unless defined( $args{'use_production_system'} );

	# Build the object, blessed with the child's class to simplify new() in
	# children classes.
	my $self = bless(
		{
			map { $_ => $args{ $_ } }
				qw( merchant_id username version password use_production_system )
		},
		$class,
	);

	return $self;
}


=head2 list_loaded()

Return a list of report modules that have been loaded, either via a "use" or
dynamically when calling build().

	my $loaded_report_modules = $report_factory->list_loaded();

=cut

sub list_loaded
{
	my ( $self ) = @_;

	if ( !defined( $LOADED_REPORT_MODULES ) )
	{
		$LOADED_REPORT_MODULES = {};

		my $main_module_path = __PACKAGE__;
		$main_module_path =~ s/::/\//g;

		foreach my $module ( keys %INC )
		{
			next unless $module =~ m/^\Q$main_module_path\/\E([^\/]+)\.pm/;
			$LOADED_REPORT_MODULES->{ $1 } = undef;
		}
	}

	return [ keys %$LOADED_REPORT_MODULES ];
}


=head2 build()

Create a Business::CyberSource::Report::* object with the correct connection
parameters.

	# Use the factory to get a Business::CyberSource::Report::Test object with
	# the correct connection parameters.
	my $test_report = $report_factory->build( 'SingleTransaction' );

Parameters:

=over

=item *

The submodule name, such as SingleTransaction for
Business::CyberSource::Report::SingleTransaction.

=back

=cut

sub build
{
	my ( $self, $module ) = @_;

	croak 'Please specify the name of the module to build'
		if !defined( $module ) || ( $module eq '' );

	my $class = __PACKAGE__ . '::' . $module;

	# If the module isn't already loaded, do that now.
	if ( scalar( grep { $module eq $_ } @{ $self->list_loaded() || [] } ) == 0 )
	{
		Class::Load::load_optional_class( $class ) || croak "Failed to load $class, double-check the class name";
		$LOADED_REPORT_MODULES->{ $module } = undef;
	}

	my $object = bless(
		# Create a copy of the factory's guts, the object will be a subclass of
		# the factory and will be able to use all the information.
		# Also, we don't want a change in the factory parameters to cascade to
		# the objects previously built, so it makes sense to copy.
		# TBD: copy only a selected subset of the content?
		Storable::dclone( $self ),
		$class,
	);

	return $object;
}


=head1 ACCESSORS

=head2 get_username()

Return the username to use to connect to the service.

	my $username = $report_factory->get_username();

=cut

sub get_username
{
	my ( $self ) = @_;

	return $self->{'username'};
}


=head2 get_password()

Return the password to use to connect to the service.

	my $password = $report_factory->get_password();

=cut

sub get_password
{
	my ( $self ) = @_;

	return $self->{'password'};
}


=head2 get_merchant_id()

Return the merchant ID to use to connect to the service.

	my $merchant_id = $report_factory->get_merchant_id();

=cut

sub get_merchant_id
{
	my ( $self ) = @_;

	return $self->{'merchant_id'};
}


=head2 use_production_system()

Return a boolean indicating whether the production system is used in queries.
Otherwise, the Test Business Center is used.

	my $use_production_system = $report_factory->use_production_system();

=cut

sub use_production_system
{
	my ( $self ) = @_;

	return $self->{'use_production_system'} ? 1 : 0;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Business-CyberSource-Report/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::CyberSource::Report


You can also look for information at:

=over

=item *

GitHub's request tracker

L<https://github.com/guillaumeaubert/Business-CyberSource-Report/issues>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/business-cybersource-report>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/business-cybersource-report>

=item *

MetaCPAN

L<https://metacpan.org/release/Business-CyberSource-Report>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>, C<< <aubertg at cpan.org> >>.


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!


=head1 COPYRIGHT & LICENSE

Copyright 2011-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
