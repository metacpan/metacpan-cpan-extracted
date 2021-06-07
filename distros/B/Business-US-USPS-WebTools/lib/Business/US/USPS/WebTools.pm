use v5.10;
use utf8;

package Business::US::USPS::WebTools;
use strict;
no warnings 'uninitialized';

use Carp qw(carp croak);

use subs qw();
use vars qw($VERSION);

$VERSION = '1.125';

=encoding utf8

=head1 NAME

Business::US::USPS::WebTools - Use the US Postal Service Web Tools

=head1 SYNOPSIS

	use Business::US::USPS::WebTools;

	# see subclasses for API details

=head1 DESCRIPTION

*** THIS IS ALPHA SOFTWARE ***

This is the base class for the WebTools web service from the US Postal
Service. The USPS offers several services, and this module handles the
parts common to all of them: making the request, getting the response,
parsing error reponses, and so on. The interesting stuff happens in
one of the subclasses which implement a particular service. So far,
the only subclass in this distribution is
C<Business::US::USPS::WebTools::AddressStandardization>.

=over

=cut

=item new( ANONYMOUS_HASH )

Make the web service object. Pass is an anonymous hash with these keys:

	UserID		the user id provided by the USPS
	Password	the password provided by the USPS
	Testing		true or false, to select the right server

If you don't pass the UserID or Password entries, C<new> looks in the
environment variables USPS_WEBTOOLS_USERID and USPS_WEBTOOLS_PASSWORD.

If C<new> cannot find both the User ID and the Password, it croaks.

If you pass a true value with the Testing key, the object will use the
testing server host name and the testing URL path. If the Testing key
is false or not present, the object uses the live server details.

=cut

sub new {
	my( $class, $args ) = @_;

	my $user_id = $args->{UserID} || $ENV{USPS_WEBTOOLS_USERID} ||
		croak "No user ID for USPS WebTools! Pass UserID or set the USPS_WEBTOOLS_USERID environment varaible.";

	my $password = $args->{Password} || $ENV{USPS_WEBTOOLS_PASSWORD} ||
		croak "No password for USPS WebTools! Pass Password or set the USPS_WEBTOOLS_PASSWORD environment variable.";

	$args->{UserID}   = $user_id;
	$args->{Password} = $password;
	$args->{testing}  = $args->{Testing} || 0;
	$args->{live}     = ! $args->{Testing};

	bless $args, $class;
	}

sub _testing { $_[0]->{testing} }
sub _live    { $_[0]->{live}    }

=item userid

Returns the User ID for the web service. You need to get this from the
US Postal Service.

=item password

Returns the Password for the web service. You need to get this from the
US Postal Service.

=item url

Returns the URL for the request to the web service. So far, all requests
are GET request with all of the data in the query string.

=item tx

Returns the transaction from the Mojo::UserAgent request.

=item response

Returns the response from the web service. This is the slightly modified
response. So far it only fixes up line endings and normalizes some error
output for inconsistent responses from different physical servers.

=cut

sub userid   { $_[0]->{UserID} }
sub password { $_[0]->{Password} }

sub url      { $_[0]->{url} || $_[0]->_make_url( $_[1] ) }
sub tx       { $_[0]->{transaction} }
sub response { $_[0]->{response} }

sub _api_host {
	my $self = shift;

	if( $self->_testing ) { $self->test_server_host }
	elsif( $self->_live ) { $self->live_server_host }
	else                  { die "Am I testing or live?" }
	}

sub _api_path {
	$_[0]->_live ?
		"/ShippingAPI.dll"
			:
		"/ShippingAPI.dll"
		}

sub _make_url {
	state $rc = require Mojo::URL;
	my( $self, $hash ) = @_;

	$self->{url} = Mojo::URL->new
		->scheme('https')
		->host( $self->_api_host )
		->path( $self->_api_path )
		->query(
			API => $self->_api_name,
			XML => $self->_make_query_xml( $hash )
			);
	}

sub _make_request {
	my( $self, $url ) = @_;
	state $rc = require Mojo::UserAgent;
	state $ua = Mojo::UserAgent->new;

	$self->{error} = undef;

	$self->{transaction} = $ua->get( $self->url );
	$self->{response} = $self->{transaction}->result->body;

	$self->is_error;

	use Data::Dumper;
#	print STDERR "In _make_request:\n" . Dumper( $self ) . "\n";

	$self->{response};
	}

sub _clone {
	my $rc = require Storable;
	my( $self ) = @_;

	my $clone = Storable::dclone( $self );
	}

=item is_error

Returns true if the response to the last request was an error, and false
otherwise.

If the response was an error, this method sets various fields in the
object:

	$self->{error}{number}
	$self->{error}{source}
	$self->{error}{description}
	$self->{error}{help_file}
	$self->{error}{help_context}

=cut

sub is_error {
	my $self = shift;

	return 0 unless $self->response =~ "<Error>";

	$self->{error} = {};

	# Apparently not all servers return this string in the
	# same way. Some have SOL and some have SoL
	$self->{response} =~ s/SOLServer/SOLServer/ig;

	( $self->{error}{number}       ) = $self->response =~ m|<Number>(-?\d+)</Number>|g;
	( $self->{error}{source}       ) = $self->response =~ m|<Source>(.*?)</Source>|g;
	( $self->{error}{description}  ) = $self->response =~ m|<Description>(.*?)</Description>|g;
	( $self->{error}{help_file}    ) = $self->response =~ m|<HelpFile>(.*?)</HelpFile>|ig;
	( $self->{error}{help_context} ) = $self->response =~ m|<HelpContext>(.*?)</HelpContext>|ig;

	1;
	}

=item live_server_host

This is production.shippingapis.com. The modules choose this host
when you have not set C<Testing> to a true value.

=item test_server_host

For most APIs, this is testing.shippingapis.com. The modules choose this host
when you have set C<Testing> to a true value.

=cut

sub live_server_host { "production.shippingapis.com" };
sub test_server_host { "stg-production.shippingapis.com" };


=back

=head1 SEE ALSO

The WebTools API is documented on the US Postal Service's website:

	http://www.usps.com/webtools/htm/Address-Information.htm

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/ssimms/business-us-usps-webtools

=head1 AUTHOR

brian d foy

=head1 MAINTAINER

Steve Simms

=head1 COPYRIGHT AND LICENSE

Copyright © 2020, Steve Simms. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
