# NAME

Business::Fixflo - Perl library for interacting with the Fixflo API
(https://www.fixflo.com)

<div>

    <a href='https://travis-ci.org/Humanstate/business-fixflo?branch=master'><img src='https://travis-ci.org/Humanstate/business-fixflo.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/business-fixflo?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-fixflo/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.33

# DESCRIPTION

Business::Fixflo is a library for easy interface to the fixflo property
repair service, it implements all of the functionality currently found
in the service's API documentation: http://www.fixflo.com/Tech/WebAPI

**You should refer to the official fixflo API documentation in conjunction**
**with this perldoc**, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods.

Please note this library is a work in progress

# SYNOPSIS

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

# ERROR HANDLING

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

You can view some useful debugging information by setting the FIXFLO\_DEBUG
env varible, this will show the calls to the Fixflo endpoints as well as a
stack trace in the event of exceptions:

    $ENV{FIXFLO_DEBUG} = 1;

# ATTRIBUTES

## username

Your Fixflo username (required if api\_key not supplied)

## password

Your Fixflo password (required if api\_key not supplied)

## api\_key

Your Fixflo API Key (required if username and password not supplied)

## custom\_domain

Your Fixflo custom domain, defaults to "api" (which will in fact call
the third party Fixflo API)

## url\_suffix

The url suffix to use after the custom domain, defaults to fixflo.com

## client

A Business::Fixflo::Client object, this will be constructed for you so
you shouldn't need to pass this

# METHODS

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

Get a \[list of\] issue(s) / agenc(y|ies) / propert(y|ies) / property address(es) / landlord(s) / landlord\_property:

    my $paginator = $ff->issues( %query_params );

    my $issue     = $ff->issue( $id );

Will return a [Business::Fixflo::Paginator](https://metacpan.org/pod/Business::Fixflo::Paginator) object (when calling endpoints
that return lists of items) or a Business::Fixflo:: object for the Issue,
Agency, etc.

%query\_params refers to the possible query params as shown in the currency
Fixflo API documentation. For example: page=\[n\]. You can pass DateTime objects
through and these will be correctly changed into strings when calling the API:

    # issues raised in the previous month
    my $paginator = $ff->issues(
        CreatedSince  => DateTime->now->subtract( months => 1 ),
    );

    # properties in given postal code
    my $paginator = $ff->properties(
        Keywords => 'NW1',
    );

Refer to the [Business::Fixflo::Paginator](https://metacpan.org/pod/Business::Fixflo::Paginator) documentation for what to do with
the returned paginator object.

Note the property method can take a flag to indicate that the passed $id is an
external reference:

    my $Property = $ff->property( 'P123',1 );

Note the landlord method can take a flag to indicate that the passed $id is an
email address

    my $Landlord = $ff->landlord( 'leejo@cpan.org',1 );

Note the landlord\_property method can take two arguments, it only one is passed
this is taken as the LandlordPropertyId, if two arguments are passed they are
taken as the LandlordId and the PropertyId:

    my $LandlordProperty = $ff->landlord_property( $landlord_property_id );

    my $LandlordProperty = $ff->landlord_property( $landlord_id,$property_id );

# EXAMPLES

See the t/002\_end\_to\_end.t test included with this distribution. you can run
this test against the fixflo test server (requires ENV variables to set the
Fixflo credentials)

# SEE ALSO

[Business::Fixflo::Address](https://metacpan.org/pod/Business::Fixflo::Address)

[Business::Fixflo::Agency](https://metacpan.org/pod/Business::Fixflo::Agency)

[Business::Fixflo::Client](https://metacpan.org/pod/Business::Fixflo::Client)

[Business::Fixflo::Issue](https://metacpan.org/pod/Business::Fixflo::Issue)

[Business::Fixflo::IssueDraft](https://metacpan.org/pod/Business::Fixflo::IssueDraft)

[Business::Fixflo::IssueDraftMedia](https://metacpan.org/pod/Business::Fixflo::IssueDraftMedia)

[Business::Fixflo::Landlord](https://metacpan.org/pod/Business::Fixflo::Landlord)

[Business::Fixflo::LandlordProperty](https://metacpan.org/pod/Business::Fixflo::LandlordProperty)

[Business::Fixflo::Paginator](https://metacpan.org/pod/Business::Fixflo::Paginator)

[Business::Fixflo::Property](https://metacpan.org/pod/Business::Fixflo::Property)

[Business::Fixflo::PropertyAddress](https://metacpan.org/pod/Business::Fixflo::PropertyAddress)

[Business::Fixflo::QuickViewPanel](https://metacpan.org/pod/Business::Fixflo::QuickViewPanel)

[http://www.fixflo.com/Tech/Api/V2/Urls](http://www.fixflo.com/Tech/Api/V2/Urls)

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo
