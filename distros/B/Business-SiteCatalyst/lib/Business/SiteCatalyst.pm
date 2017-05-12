package Business::SiteCatalyst;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use LWP::UserAgent qw();
use HTTP::Request qw();
use JSON qw();
use Digest::MD5 qw();
use POSIX qw();
use Digest::SHA1 qw();
use MIME::Base64 qw();

use Business::SiteCatalyst::Company;
use Business::SiteCatalyst::Report;


# Some API methods return strings or numbers rather than valid JSON.
# This list is used to return the raw response to the caller instead of decoding output as JSON
my %METHODS_RETURNING_INVALID_JSON = 
(
	'Company.GetEndpoint'   => 1,  # Returns string
	'Company.GetTokenCount' => 1,  # Returns number
	'Report.CancelReport'   => 1,  # Returns number
);


=head1 NAME

Business::SiteCatalyst - Interface to Adobe Omniture SiteCatalyst's REST API.


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

NOTE: the 'api_subdomain' option/config variable is utilized for the api url.
To determine your specific API URL/Endpoint, please visit
https://developer.omniture.com/en_US/get-started/api-explorer
Most users won't need to set this variable unless the default causes errors.

API URL: 'https://' . $api_subdomain . '.omniture.com/admin/1.3/rest/?'


	use Business::SiteCatalyst;
	
	# Create an object to communicate with Adobe SiteCatalyst
	my $site_catalyst = Business::SiteCatalyst->new(
		username        => 'dummyusername',
		shared_secret   => 'dummysecret',
		api_subdomain   => 'api|api2', #optional; default value='api'
	);


=head1 METHODS

=head2 new()

Create a new Adobe SiteCatalyst object that will be used as the interface with
Adobe SiteCatalyst's API

	use Business::SiteCatalyst;
	
	# Create an object to communicate with Adobe SiteCatalyst
	my $site_catalyst = Business::SiteCatalyst->new(
		username        => 'dummyusername',
		shared_secret   => 'dummysecret',
		api_subdomain   => 'api|api2', #optional; default value='api'
	);

Creates a new object to communicate with Adobe SiteCatalyst.

'username' and 'shared_secret' are mandatory.
The 'verbose' parameter is optional and defaults to not verbose.

=cut

sub new
{
	my ( $class, %args ) = @_;
	
	# Check for mandatory parameters
	foreach my $arg ( qw( username shared_secret ) )
	{
		croak "Argument '$arg' is needed to create the Business::SiteCatalyst object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	#Defaults.
	
	# NOTE - some users connect to api2.omniture.com, so the subdomain portion of the host is configurable
	# in the 'api_subdomain' config variable in SiteCatalystConfig.pm
	my $webservice_url = 'https://' .
		( defined $args{'api_subdomain'} ? $args{'api_subdomain'} : 'api' ) .
		'.omniture.com/admin/1.3/rest/?method=';
	
	# Create the object
	my $self = bless(
		{
			username        => $args{'username'},
			shared_secret   => $args{'shared_secret'},
			webservice_url  => $webservice_url,
		},
		$class,
	);
	
	$self->verbose( $args{'verbose'} );
	
	return $self;
}


=head2 instantiate_report()

Create a new Business::SiteCatalyst::Report object, which
will allow retrieval of SiteCatalyst reports.

	# Create a new report
	my $report = $site_catalyst->instantiate_report(
		type            => 'report type',
		report_suite_id => 'report suite id',
	);

	# Act on an existing report
	my $report = $site_catalyst->instantiate_report(
		report_id       => 'report id',
	);

	
Parameters:

=over 4

=item * type

The type of the report to instantiate. 
Acceptable values are 'Overtime', 'Ranked', and 'Trended'.

=item * report_suite_id

The Report Suite ID you want to pull data from.

=item * report_id

The id of the existing report you want to check status of, retrieve results for,
or cancel processing.

=back

=cut

sub instantiate_report
{
	my ( $self, %args ) = @_;
	
	return Business::SiteCatalyst::Report->new( $self, %args );
}



=head2 instantiate_company()

Create a new Business::SiteCatalyst::Company object, which
will allow retrieval of company-specific SiteCatalyst data.

	my $company = $site_catalyst->instantiate_company();

	
Parameters: none

=cut

sub instantiate_company
{
	my ( $self, %args ) = @_;
	
	return Business::SiteCatalyst::Company->new( $self, %args );
}


=head1 INTERNAL METHODS

=head2 send_request()

Internal, formats the JSON call with the arguments provided and checks the
reply.

	my ( $error, $response_data ) = $site_catalyst->send_request(
		method => $method,
		data   => $data,
	);

=cut

sub send_request
{
	my ( $self, %args ) = @_;
	
	my $verbose = $self->verbose();
	my $url = $self->{'webservice_url'} .  $args{'method'};
	
	# Check for mandatory parameters
	foreach my $arg ( qw( method data ) )
	{
		croak "Argument '$arg' is needed to send a request with the Business::SiteCatalyst object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	my $json_in = JSON::encode_json( $args{'data'} );
	carp "Sending JSON request >" . ( defined( $json_in ) ? $json_in : '' ) . "<"
		if $verbose;
	
	# Authentication information for header.
	my $username = $self->{'username'};
	my $nonce = Digest::MD5::md5_hex( rand() * time() );
	chomp($nonce);
	
	my $created = POSIX::strftime("%Y-%m-%dT%H:%M:%S", gmtime());
	my $password_digest = MIME::Base64::encode_base64(
		Digest::SHA1::sha1_hex( $nonce . $created . $self->{'shared_secret'} ) 
	);
	chomp($password_digest);
	
	my $request = HTTP::Request->new(POST => $url);
	carp "POSTing request to URL >" . ( defined( $url ) ? $url : '' ) . "<"
		if $verbose;
	my $auth_header = qq|UsernameToken Username="$username", PasswordDigest="$password_digest", Nonce="$nonce", Created="$created"|;
	carp "Auth header: >$auth_header<" if $verbose;
	
	$request->header('X-WSSE', $auth_header);
	
	$request->content_type('application/json');
	$request->content( $json_in );
	
	my $user_agent = LWP::UserAgent->new();
	my $response = $user_agent->request($request);
	
	croak "Request failed:" . $response->status_line()
		if !$response->is_success();

	carp "Response >" . ( defined( $response ) ? $response->content() : '' ) . "<"
		if $verbose;

	my $json_out;
	
	if ( exists( $METHODS_RETURNING_INVALID_JSON{ $args{'method'} } ) )
	{
		$json_out = $response->content();
	}
	else
	{
		$json_out = JSON::decode_json( $response->content() );
	}
	
	carp "JSON Response >" . ( defined( $json_out ) ? Dumper($json_out) : '' ) . "<"
		if $verbose;
	
	return $json_out;
}


=head2 verbose()

Control the verbosity of the debugging output.

$site_catalyst->verbose( 1 ); # turn on verbose information

$site_catalyst->verbose( 0 ); # quiet!

warn 'Verbose' if $site_catalyst->verbose(); # getter-style

=cut

sub verbose
{
	my ( $self, $verbose ) = @_;
	
	$self->{'verbose'} = ( $verbose || 0 )
		if defined( $verbose );
	
	return $self->{'verbose'};
}


=head1 RUNNING TESTS

By default, only basic tests that do not require a connection to Adobe
SiteCatalyst's platform are run in t/.

To run the developer tests, you will need to do the following:

=over 4

=item *

Request access to Adobe web services from your Adobe Online Marketing Suite administrator.

=item *

In Adobe SiteCatalyst's interface, you will need to log in as an admin, then go
to the "Admin" tab, "Admin Console > Company > Web Services". There you can find
your "shared secret" for your username.

=item *

Your report suite IDs can be found in Adobe SiteCatalyst's interface. Visit 
"Admin > Admin Console > Report Suites".

=back

You can now create a file named SiteCatalystConfig.pm in your own directory, with
the following content:

	package Adobe SiteCatalystConfig;
	
	sub new
	{
		return
		{
			username                => 'username',
			shared_secret           => 'shared_secret',
			report_suite_id         => 'report_suite_id',
			api_subdomain           => 'api|api2', #optional. default='api'
			verbose                 => 0, # Enable this for debugging output
		};
	}
	
	1;

You will then be able to run all the tests included in this distribution, after
adding the path to Adobe SiteCatalystConfig.pm to your library paths.


=head1 AUTHOR

Jennifer Pinkham, C<< <jpinkham at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-Business-SiteCatalyst at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-SiteCatalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::SiteCatalyst


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
at Geeknet (L<http://www.geek.net/>), for footing the bill while I write code for them!
Special thanks for technical help from fellow ThinkGeek CPAN author Guillaume Aubert L<http://search.cpan.org/~aubertg/>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Jennifer Pinkham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
