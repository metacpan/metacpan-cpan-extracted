package Business::SiteCatalyst::Company;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Data::Validate::Type;


=head1 NAME

Business::SiteCatalyst::Company - Interface to Adobe Omniture SiteCatalyst's REST API 'Company' module.


=head1 VERSION

Version 1.2.2

=cut

our $VERSION = '1.2.2';


=head1 SYNOPSIS

This module allows you to interact with Adobe (formerly Omniture) SiteCatalyst,
a web analytics service. It encapsulates all the communications with the API 
provided by Adobe SiteCatalyst to offer a Perl interface for managing reports,
pulling company-specific SiteCatalyst data (ex: token usage), uploading SAINT 
data (feature not implemented yet), etc.

Please note that you will need to have purchased the Adobe SiteCatalyst product,
and have web services enabled within your account first in order to obtain a web
services shared secret, as well as agree with the Terms and Conditions for using 
the API.

See SiteCatalyst API Explorer at
https://developer.omniture.com/en_US/get-started/api-explorer
for 'Company' module documentation
	

	use Business::SiteCatalyst;
	
	# Create an object to communicate with Adobe SiteCatalyst
	my $site_catalyst = Business::SiteCatalyst->new(
		username        => 'dummyusername',
		shared_secret   => 'dummysecret',
		api_subdomain   => 'api|api2', #optional; default value='api'
	);
	
	my $company = $site_catalyst->instantiate_company();
	
	my $token_data = $company->get_token_usage();
	
	my $tokens_left = $company->get_token_count();
	
	my $report_suites = $company->get_report_suites();
	
	my $tracking_server = $company->get_tracking_server();
	
	my $endpoint = $company->get_endpoint( company => $company );
	
	my $queue_list = $company->get_queue();
	
	my $success = $company->cancel_queue_item( queue_id => $queue_item_id );
	
	my $version_list = $company->get_version_access();
	
=head1 METHODS

=head2 new()

Create a new Business::SiteCatalyst::Company object, which
will allow retrieval of SiteCatalyst company-specific info.

NOTE: -This should not be called directly-. Instead, use 
C<Business::SiteCatalyst->instantiate_company()>.

	my $company = Business::SiteCatalyst::Company->new(
		$site_catalyst,
	);

Parameters: none

=cut

sub new
{
	my ( $class, $site_catalyst, %args ) = @_;
	
	# Check for mandatory parameters
	Data::Validate::Type::is_instance( $site_catalyst, class => 'Business::SiteCatalyst')
		|| croak "First argument must be a Business::SiteCatalyst object";

	# Create the object
	my $self = bless(
		{
			site_catalyst   => $site_catalyst,
		},
		$class,
	);
	
	return $self;
}


=head2 get_token_count()

Determine the number of tokens left for your company. You are alloted
10,000 tokens per month.

	my $tokens_left = $company->get_token_count();


=cut

sub get_token_count
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetTokenCount',
		data   => {'' => []}
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	
	return $response;
}



=head2 get_token_usage()

Information about the company's token usage for the current calendar month,
broken down by user account.

	my $token_data = $company->get_token_usage();


=cut

sub get_token_usage
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetTokenUsage',
		data   => {'' => []}
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	
	return $response;
}


=head2 get_site_catalyst()

Get Business::SiteCatalyst object used when creating the current object.

	my $site_catalyst = $report->get_site_catalyst();

=cut

sub get_site_catalyst
{
	my ( $self ) = @_;
	
	return $self->{'site_catalyst'};
}



=head2 get_report_suites()

Information about the company's report suites configured in SiteCatalyst.

	my $report_suites = $company->get_report_suites();


=cut

sub get_report_suites
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetReportSuites',
		data   => {'' => []}
	);
	
	if ( !defined($response) || !defined($response->{'report_suites'}) )
	{
		croak "Fatal error. No response or 'report_suites' missing from response.";
	}
	
	return $response->{'report_suites'};
}


=head2 get_tracking_server()

Returns the tracking server and namespace for the specified report suite.
If report suite is not specified, 'report_suite_id' in SiteCatalystConfig 
(if one exists) will be used.

	my $tracking_server = $company->get_tracking_server();
	my $tracking_server = $company->get_tracking_server( 
		report_suite_id => $report_suite_id 
	);

Optional parameters:

=over 4

=item * report_suite_id

The Report Suite ID you want to pull data from.

=back

=cut

sub get_tracking_server
{
	my ( $self, %args ) = @_;
	
	# If report suite was not specified as an argument, try to use value from config
	if ( !defined $args{'report_suite_id'} || $args{'report_suite_id'} eq '' )
	{
		require SiteCatalystConfig;
		my $config = SiteCatalystConfig->new();
	
		if ( defined( $config ) && $config->{'report_suite_id'} ne '' )
		{
			$args{'report_suite_id'} = $config->{'report_suite_id'};
		}
		else
		{
			croak "Argument 'report_suite_id' is required because 'report_suite_id' is not specified in SiteCatalystConfig.pm"
				if !defined( $args{'report_suite_id'} ) || ( $args{'report_suite_id'} eq '' );
		}
	}
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetTrackingServer',
		data   => { 'rsid' => $args{'report_suite_id'} }
	);
	
	if ( !defined($response) || !defined($response->{'tracking_server'}) )
	{
		croak "Fatal error. No response or missing tracking_server in response";
	}
	
	return $response->{'tracking_server'};
}


=head2 get_endpoint()

Retrieves the endpoint (API URL) for the specified company.
NOTE: You can specify any company, not just your own.

	my $endpoint = $company->get_endpoint( company => $company );

Parameters:

=over 4

=item * company

The company whose endpoint you want to retrieve.

=back

=cut

sub get_endpoint
{
	my ( $self, %args ) = @_;
	
	croak "Argument 'company' is required"
		if !defined( $args{'company'} ) || ( $args{'company'} eq '' );
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetEndpoint',
		data   => { 'company' => $args{'company'} }
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	
	return $response;
}


=head2 get_queue()

Returns queued items that are pending approval for the requesting company.

	my $queue_list = $company->get_queue();


=cut

sub get_queue
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetQueue',
		data   => {'' => []}
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}

	return $response;
}


=head2 cancel_queue_item()

Cancel a pending (queued) action that has yet to be approved.

	my $success = $company->cancel_queue_item( queue_id => $queue_item_id );

Parameters:

=over 4

=item * queue_id

The numeric identifier of the pending item you wish to cancel.

=back

=cut

sub cancel_queue_item
{
	my ( $self, %args ) = @_;
	
	croak "Argument 'queue_id' is required"
		if !defined( $args{'queue_id'} ) || ( $args{'queue_id'} eq '' );
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.CancelQueueItem',
		data   => { 'qid' => $args{'queue_id'} }
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}

	return $response eq 'true' ? 1 : 0;
}


=head2 get_version_access()

Information about the version of various Adobe services you have access to.

	my $version_list = $company->get_version_access();


=cut

sub get_version_access
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetVersionAccess',
		data   => {'' => []}
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}

	return $response;
}


=head1 AUTHOR

Jennifer Pinkham, C<< <jpinkham at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-Business-SiteCatalyst at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-SiteCatalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::SiteCatalyst::Company


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-SiteCatalyst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-SiteCatalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-SiteCatalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-SiteCatalyst/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while I write 
code for them! Special thanks for technical help from fellow ThinkGeek CPAN
author Guillaume Aubert L<http://search.cpan.org/~aubertg/>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Jennifer Pinkham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
