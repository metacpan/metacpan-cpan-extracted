package Business::CyberSource::Report::PaymentEvents;

use strict;
use warnings;

use base 'Business::CyberSource::Report';

use Carp;
use HTTP::Request::Common qw();
use LWP::UserAgent qw();


=head1 NAME

Business::CyberSource::Report::PaymentEvents - Interface to CyberSource's Payment Events report.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';

our $TEST_URL = 'https://ebctest.cybersource.com/ebctest';
our $PRODUCTION_URL = 'https://ebc.cybersource.com/ebc';


=head1 SYNOPSIS

This module is an interface to the Payment Events report from CyberSource.

	use Business::CyberSource::Report;

	# Generate a report factory.
	my $report_factory = Business::CyberSource::Report->new(
		merchant_id => $merchant_id,
		username    => $username,
		password    => $password,
	);

	# Build a Business::CyberSource::Report::PaymentEvents object.
	my $payment_events_report = $report_factory->build( 'PaymentEvents' );

	# Retrieve the Payment Events report for a given date.
	$payment_events_report->retrieve(
		format => $format,
		date   => $date,
	);


=head1 METHODS

=head2 retrieve()

Build and send the request to CyberSource.

	# Retrieve the Payment Events report for a given date.
	$payment_events_report->retrieve(
		format => $format,
		date   => $date,
	);

Parameters:

=over

=item * format (mandatory)

The desired format of the report, 'csv' or 'xml'.

=item * date (mandatory)

The date of the transactions to include in the report, using the format
YYYY/MM/DD.

=item * user_agent (optional)

By default, C<LWP::UserAgent>. This is useful for tests, see the documentation
for L<Test::LWP::UserAgent> in particular.

=back

=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	my $format = delete( $args{'format'} );
	my $date = delete( $args{'date'} );
	my $user_agent = delete( $args{'user_agent'} ) || LWP::UserAgent->new();

	# Verify the format.
	croak "The format needs to be 'csv' or 'xml'"
		unless defined( $format ) && ( $format =~ m/^(csv|xml)$/ );

	# Verify the date.
	croak 'You need to specify a date for the transactions to retrieve'
		unless defined( $date );
	croak 'The format for the date of the transactions to retrieve is YYYY/MM/DD'
		unless $date =~ m/^\d{4}\/\d{2}\/\d{2}$/;

	# Prepare the URL to hit.
	my $url = ( $self->use_production_system() ? $PRODUCTION_URL : $TEST_URL )
		. '/DownloadReport/' . $date . '/' . $self->get_merchant_id()
		. '/PaymentEventsReport.' . $format;

	# Send the query.
	my $request = HTTP::Request::Common::GET( $url );
	$request->authorization_basic(
		$self->get_username(),
		$self->get_password(),
	);

	my $response = $user_agent->request( $request );
	croak "Could not get a response from CyberSource"
		unless defined $response;
	croak "CyberSource returned the following error: " . $response->status_line()
		unless $response->is_success();

	return $response->content();
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Business-CyberSource-Report/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::CyberSource::Report::PaymentEvents


You can also look for information at:

=over 4

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
