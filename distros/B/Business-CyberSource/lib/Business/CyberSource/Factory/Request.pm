package Business::CyberSource::Factory::Request;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use MooseX::AbstractFactory;
implementation_class_via sub { 'Business::CyberSource::Request::' . shift };

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: CyberSource Request Factory Module

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Factory::Request - CyberSource Request Factory Module

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Factory::Request;

	my $factory = Business::CyberSource::Factory::Request->new;

	my $request_obj = $factory->create(
		'Authorization', {
			reference_code => '42',
			bill_to => {
				first_name  => 'Caleb',
				last_name   => 'Cushing',
				street      => '100 somewhere st',
				city        => 'Houston',
				state       => 'TX',
				postal_code => '77064',
				country     => 'US',
				email       => 'xenoterracide@gmail.com',
			},
			purchase_totals => {
				currency => 'USD',
				total    => 5.00,
				discount => 0.10, # optional
				duty     => 0.03, # optional
			},
			card => {
				account_number => '4111111111111111',
				expiration => {
					month => 9,
					year  => 2025,
				},
			},
		}
	);

=head1 DESCRIPTION

This Module is to provide a replacement for what
L<Business::CyberSource::Request> originally was, a factory. Once backwards
compatibility is no longer needed this code may be removed.

=head1 METHODS

=head2 new

=head2 create

	$factory->create( $implementation, { ... } )

Create a new request object. C<create> takes a request implementation and a hashref to pass to the
implementation's C<new> method. The implementation string accepts any
implementation whose package name is prefixed by
C<Business::CyberSource::Request::>.

	my $req = $factory->create(
			'Capture',
			{
				first_name => 'John',
				last_name  => 'Smith',
				...
			}
		);

=head1 SEE ALSO

=over

=item * L<MooseX::AbstractFactory>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
