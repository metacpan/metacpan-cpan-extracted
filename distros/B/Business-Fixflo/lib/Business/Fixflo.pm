package Business::Fixflo;

=head1 NAME

Business::Fixflo - Perl library for interacting with the Fixflo API
(https://www.fixflo.com)

=for html
<a href='https://travis-ci.org/Humanstate/business-fixflo?branch=master'><img src='https://travis-ci.org/Humanstate/business-fixflo.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/business-fixflo?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-fixflo/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.39

=head1 DESCRIPTION

Business::Fixflo is a library for easy interface to the fixflo property
repair service, it implements all of the functionality currently found
in the service's API documentation: http://www.fixflo.com/Tech/WebAPI

B<You should refer to the official fixflo API documentation in conjunction>
B<with this perldoc>, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods.

Please note this library is a work in progress

=head1 SYNOPSIS

    # agency API:
    my $ff = Business::Fixflo->new(
        custom_domain => $domain,
        api_key       => $api_key,

        # if api_key is not supplied:
        username      => $username,
        password      => $password,
    );

    my $issues   = $ff->issues,
    my $agencies = $ff->agencies,

    while ( my @issues = @{ $issues->next // [] } ) {
        foreach my $issue ( @issues ) {
            $issue->get;
            ...
        }
    }

    my $issue = $ff->issue( $id );
    my $json  = $issue->to_json;

    # third party API:
    my $ff = Business::Fixflo->new(
        api_key       => $third_party_api_key,
        username      => $third_party_username,
        password      => $third_party_password,
    );

    my $agency = Business::Fixflo::Agency->new(
        client     => $ff->client,
        AgencyName => 'foo',
    );

    $agency->create;
    $agency->delete;

=head1 ERROR HANDLING

Any problems or errors will result in a Business::Fixflo::Exception
object being thrown, so you should wrap any calls to the library in the
appropriate error catching code (ideally using a module from CPAN):

    try {
        ...
    }
    catch ( Business::Fixflo::Exception $e ) {
        # error specific to Business::Fixflo
        ...
        say $e->message;  # error message
        say $e->code;     # HTTP status code
        say $e->response; # HTTP status message

        # ->request may not always be present
        say $e->request->{path}    if $e->request
        say $e->request->{params}  if $e->request
        say $e->request->{headers} if $e->request
        say $e->request->{content} if $e->request
    }
    catch ( $e ) {
        # some other failure?
        ...
    }

You can view some useful debugging information by setting the FIXFLO_DEBUG
env varible, this will show the calls to the Fixflo endpoints as well as a
stack trace in the event of exceptions:

    $ENV{FIXFLO_DEBUG} = 1;

=cut

use strict;
use warnings;

use Moo;
with 'Business::Fixflo::Version';

$Business::Fixflo::VERSION = '0.39';

use Carp qw/ confess /;

use Business::Fixflo::Client;

=head1 ATTRIBUTES

=head2 username

Your Fixflo username (required if api_key not supplied)

=head2 password

Your Fixflo password (required if api_key not supplied)

=head2 api_key

Your Fixflo API Key (required if username and password not supplied)

=head2 custom_domain

Your Fixflo custom domain, defaults to "api" (which will in fact call
the third party Fixflo API)

=head2 url_suffix

The url suffix to use after the custom domain, defaults to fixflo.com

=head2 client

A Business::Fixflo::Client object, this will be constructed for you so
you shouldn't need to pass this

=cut

has [ qw/ username password api_key / ] => (
    is       => 'ro',
    required => 0,
);

has custom_domain => (
    is       => 'ro',
    required => 0,
    default  => sub { 'api' },
);

has url_suffix => (
    is       => 'ro',
    required => 0,
    default  => sub { 'fixflo.com' },
);

has url_scheme => (
    is       => 'ro',
    required => 0,
    default  => sub { 'https' },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::Fixflo::Client" )
            if ref $_[0] ne 'Business::Fixflo::Client';
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        if ( $self->url_suffix =~ /\Qtest.fixflo.com\E/ ) {
            $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
        }

        return Business::Fixflo::Client->new(
            api_key       => $self->api_key,
            username      => $self->username,
            password      => $self->password,
            custom_domain => $self->custom_domain,
            url_suffix    => $self->url_suffix,
            url_scheme    => $self->url_scheme,
        );
    },
);

=head1 METHODS

    issues
    agencies
    landlords
    properties
    property_addresses
    issue
    issue_draft
    issue_draft_media
    landlord
    landlord_property
    agency
    property
    property_address
    quick_view_panels

Get a [list of] issue(s) / agenc(y|ies) / propert(y|ies) / property address(es) / landlord(s) / landlord_property:

    my $paginator = $ff->issues( %query_params );

    my $issue     = $ff->issue( $id );

Will return a L<Business::Fixflo::Paginator> object (when calling endpoints
that return lists of items) or a Business::Fixflo:: object for the Issue,
Agency, etc.

%query_params refers to the possible query params as shown in the currency
Fixflo API documentation. For example: page=[n]. You can pass DateTime objects
through and these will be correctly changed into strings when calling the API:

    # issues raised in the previous month
    my $paginator = $ff->issues(
        CreatedSince  => DateTime->now->subtract( months => 1 ),
    );

    # properties in given postal code
    my $paginator = $ff->properties(
        Keywords => 'NW1',
    );

Refer to the L<Business::Fixflo::Paginator> documentation for what to do with
the returned paginator object.

Note the property method can take a flag to indicate that the passed $id is an
external reference:

    my $Property = $ff->property( 'P123',1 );

Note the landlord method can take a flag to indicate that the passed $id is an
email address

    my $Landlord = $ff->landlord( 'leejo@cpan.org',1 );

Note the landlord_property method can take two arguments, it only one is passed
this is taken as the LandlordPropertyId, if two arguments are passed they are
taken as the LandlordId and the PropertyId:

    my $LandlordProperty = $ff->landlord_property( $landlord_property_id );

    my $LandlordProperty = $ff->landlord_property( $landlord_id,$property_id );

=cut

sub issues {
    my ( $self,%params ) = @_;
    return $self->client->_get_issues( \%params );
}

sub agencies {
    my ( $self,%params ) = @_;
    return $self->client->_get_agencies( \%params );
}

sub properties {
    my ( $self,%params ) = @_;
    return $self->client->_get_properties( \%params );
}

sub landlords {
    my ( $self,%params ) = @_;
    return $self->client->_get_landlords( \%params );
}

sub property_addresses {
    my ( $self,%params ) = @_;
    return $self->client->_get_property_addresses( \%params );
}

sub issue {
    my ( $self,$id ) = @_;
    return $self->client->_get_issue( $id );
}

sub issue_draft {
    my ( $self,$id ) = @_;
    return $self->client->_get_issue_draft( $id );
}

sub issue_draft_media {
    my ( $self,$id ) = @_;
    return $self->client->_get_issue_draft_media( $id );
}

sub agency {
    my ( $self,$id ) = @_;
    return $self->client->_get_agency( $id );
}

sub property {
    my ( $self,$id,$is_external_id ) = @_;
    return $self->client->_get_property( $id,$is_external_id );
}

sub landlord {
    my ( $self,$id,$is_external_id ) = @_;
    return $self->client->_get_landlord( $id,$is_external_id );
}

sub landlord_property {
    my ( $self,$id_or_landlord_id,$property_id ) = @_;
    return $self->client->_get_landlord_property( $id_or_landlord_id,$property_id );
}

sub property_address {
    my ( $self,$id ) = @_;
    return $self->client->_get_property_address( $id );
}

sub quick_view_panels {
    my ( $self ) = @_;
    return $self->client->_get_quick_view_panels;
}

=head1 EXAMPLES

See the t/002_end_to_end.t test included with this distribution. you can run
this test against the fixflo test server (requires ENV variables to set the
Fixflo credentials)

=head1 SEE ALSO

L<Business::Fixflo::Address>

L<Business::Fixflo::Agency>

L<Business::Fixflo::Client>

L<Business::Fixflo::Issue>

L<Business::Fixflo::IssueDraft>

L<Business::Fixflo::IssueDraftMedia>

L<Business::Fixflo::Landlord>

L<Business::Fixflo::LandlordProperty>

L<Business::Fixflo::Paginator>

L<Business::Fixflo::Property>

L<Business::Fixflo::PropertyAddress>

L<Business::Fixflo::QuickViewPanel>

L<http://www.fixflo.com/Tech/Api/V2/Urls>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
