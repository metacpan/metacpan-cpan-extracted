# NAME

Business::GoCardless - Perl library for interacting with the GoCardless Basic v1 API
(https://gocardless.com)

<div>

    <a href='https://travis-ci.org/Humanstate/business-gocardless?branch=master'><img src='https://travis-ci.org/Humanstate/business-gocardless.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/business-gocardless?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-gocardless/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.16

# DESCRIPTION

Business::GoCardless is a library for easy interface to the gocardless
payment service, it implements most of the functionality currently found
in the service's API documentation: https://developer.gocardless.com

Current missing functionality is partner account handling, but all resource
manipulation (Bill, Merchant, Payout etc) is handled along with webhooks and
the checking/generation of signature, nonce, param normalisation, and other
such lower level interface with the API.

Please note this library is only compatible with the Basic v1 GoCardless API,
which GoCardless are now calling "The Legacy GoCardless API". These modules
will not function with the Basic v2+ and Pro GoCardless APIs. A library
to use the v2 API is in development.

**You should refer to the official gocardless API documentation in conjunction**
**with this perldoc**, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods. [https://developer.gocardless.com](https://developer.gocardless.com), specifically the docs for the
v1 GoCardless API at [https://developer.gocardless.com/legacy](https://developer.gocardless.com/legacy).

# SYNOPSIS

The following examples show instantiating the object and getting a resource
(Bill in this case) to manipulate. For more examples see the t/002\_end\_to\_end.t
script, which can be run against the gocardless sandbox (or even live) endpoint
when given the necessary ENV variables.

    my $GoCardless = Business::GoCardless->new(
        token           => $your_gocardless_token
        client_details  => {
            base_url    => $gocardless_url, # defaults to https://gocardless.com
            app_id      => $your_gocardless_app_id,
            app_secret  => $your_gocardless_app_secret,
            merchant_id => $your_gocardless_merchant_id,
        },
    );

    # get merchant details
    my $Merchant = $GoCardless->merchant;

    # create URL for a one off bill (https://developer.gocardless.com/#create-a-one-off-bill)
    my $new_bill_url = $GoCardless->new_bill_url(
        amount       => 100,
        name         => "Some Bill",
        description  => "Some Bill Description",
        user         => $user_hash,
        redirect_uri => "https://foo/success",
        cancel_uri   => "https://foo/cancel",
        state        => "some_state_data",
    );

    # having sent the user to the $new_bill_url and them having complete it,
    # we need to confirm the resource using the details sent by gocardless to
    # the redirect_uri (https://developer.gocardless.com/#confirm-a-new-one-off-bill)
    my $Bill = $GoCardless->confirm_resource(
        resource_uri  => $uri,
        resource_type => 'bill', # in the above case
        resource_id   => $bill_id,
        signature     => $signature,
        state         => "some_state_data",
    );

    # get a specfic Bill
    $Bill = $GoCardless->bill( $id );

    # cancel the bill
    $Bill->cancel;

    # too late? maybe we should refund instead
    $Bill->refund;

    # or maybe it failed?
    $Bill->retry if $Bill->failed;

    # get a list of Bill objects (filter optional: https://developer.gocardless.com/#filtering)
    my @bills = $GoCardless->bills( %filter );

    # on any resource object:
    my %data = $Bill->to_hash;
    my $json = $Bill->to_json;

# ERROR HANDLING

Any problems or errors will result in a Business::GoCardless::Exception
object being thrown, so you should wrap any calls to the library in the
appropriate error catching code (ideally using a module from CPAN):

    try {
        my $Pager = $GoCardless->bills;

        while( my @bills = $Pager->next ) {
            foreach my $Bill ( @bills ) {
                $Bill->cancel;
            }
        }
    }
    catch ( Business::GoCardless::Exception $e ) {
        # error specific to Business::GoCardless
        ...
        say $e->message;  # error message
        say $e->code;     # HTTP status code
        say $e->response; # HTTP status message
    }
    catch ( $e ) {
        # some other failure?
        ...
    }

# PAGINATION

Any methods marked as **pager** have a dual interface, when called in list context
they will return the first 100 resource objects, when called in scalar context they
will return a [Business::GoCardless::Paginator](https://metacpan.org/pod/Business::GoCardless::Paginator) object allowing you to iterate
through all the objects:

    # get a list of L<Business::GoCardless::Bill> objects
    # (filter optional: https://developer.gocardless.com/#filtering)
    my @bills = $GoCardless->bills( %filter );

    # or using the Business::GoCardless::Paginator object:
    my $Pager = $GoCardless->bills;

    while( my @bills = $Pager->next ) {
        foreach my $Bill ( @bills ) {
            ...
        }
    }

# ATTRIBUTES

## token

Your gocardless API token, this attribute is required.

## client\_details

Hash of gocardless client details, passed to [Business::GoCardless::Client](https://metacpan.org/pod/Business::GoCardless::Client).

    base_url    => $gocardless_url, # defaults to https://gocardless.com
    app_id      => $your_gocardless_app_id,
    app_secret  => $your_gocardless_app_secret,
    merchant_id => $your_gocardless_merchant_id,

## client

The client object, defaults to [Business::GoCardless::Client](https://metacpan.org/pod/Business::GoCardless::Client).

# Common Methods

Methods not tied to any particular resource.

## confirm\_resource

Confirm a resource.

    my $Bill = $GoCardless->confirm_resource(
        resource_uri  => $uri,
        resource_type => 'bill',
        resource_id   => $bill_id,
        signature     => $signature,
        state         => "some_state_data",
    );

# Bill Methods

See [Business::GoCardless::Bill](https://metacpan.org/pod/Business::GoCardless::Bill) for more information on Bill operations.

## new\_bill\_url

Create a URL for generating a one off bill:

    my $new_bill_url = $GoCardless->new_bill_url(
        amount => 100,
    );

## bill

Get a [Business::GoCardless::Bill](https://metacpan.org/pod/Business::GoCardless::Bill) object for a specific bill.

    my $Bill = $GoCardless->bill( $id );

## bills (**pager**)

Get a list of Bill objects (%filter is optional).

    my @bills = $GoCardless->bills( %filter );

# Merchant Methods

See [Business::GoCardless::Merchant](https://metacpan.org/pod/Business::GoCardless::Merchant) for more information on Merchant operations.

## merchant

Get object that represents you (Merchant)

    my $Merchant = $GoCardless->merchant;

## payouts (**pager**)

Get a list of [Business::GoCardless::Payout](https://metacpan.org/pod/Business::GoCardless::Payout) objects.

    my @payouts = $GoCardless->payouts;

# Payout Methods

See [Business::GoCardless::Payout](https://metacpan.org/pod/Business::GoCardless::Payout) for more information on Payout operations.

## payout

Get a [Business::GoCardless::Payout](https://metacpan.org/pod/Business::GoCardless::Payout) object for a specific payout.

    my $Payout = $GoCardless->payout( $id );

# PreAuthorization Methods

See [Business::GoCardless::PreAuthorization](https://metacpan.org/pod/Business::GoCardless::PreAuthorization) for more information on PreAuthorization operations.

## new\_pre\_authorization\_url

Create a URL for generating a pre\_authorization.

    my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
        max_amount      => 100,
        interval_length => 10,
        interval_unit   => 'day',
    );

## pre\_authorization

Get a [Business::GoCardless::PreAuthorization](https://metacpan.org/pod/Business::GoCardless::PreAuthorization) object for a specific pre\_authorization.

    my $PreAuth = $GoCardless->pre_authorization( $id );

## pre\_authorizations (**pager**)

Get a list of [Business::GoCardless::PreAuthorization](https://metacpan.org/pod/Business::GoCardless::PreAuthorization) objects.

    my @pre_auths = $GoCardless->pre_authorizations;

# Subscription Methods

See [Business::GoCardless::Subscription](https://metacpan.org/pod/Business::GoCardless::Subscription) for more information on Subscription operations.

## new\_subscription\_url

Create a URL for generating a subscription.

    my $new_pre_auth_url = $GoCardless->new_subscription_url(
        amount          => 100,
        interval_length => 1,
        interval_unit   => 'month',
    );

## subscription

Get a [Business::GoCardless::Subscription](https://metacpan.org/pod/Business::GoCardless::Subscription) object for a specific subscription.

    my $Subscription = $GoCardless->subscription( $id );

## subscriptions (**pager**)

Get a list of [Business::GoCardless::Subscription](https://metacpan.org/pod/Business::GoCardless::Subscription) objects.

    my @subs = $GoCardless->subscriptions;

# User Methods

See [Business::GoCardless::User](https://metacpan.org/pod/Business::GoCardless::User) for more information on User operations.

## users (**pager**)

Get a list of [Business::GoCardless::User](https://metacpan.org/pod/Business::GoCardless::User) objects.

    my @users = $GoCardless->users;

# Webhook Methods

See [Business::GoCardless::Webhook](https://metacpan.org/pod/Business::GoCardless::Webhook) for more information on Webhook operations.

## webhook

Get a [Business::GoCardless::Webhook](https://metacpan.org/pod/Business::GoCardless::Webhook) object from the data sent to you via a
GoCardless webhook:

    my $Webhook = $GoCardless->webhook( $json_data );

# SEE ALSO

[Business::GoCardless::Resource](https://metacpan.org/pod/Business::GoCardless::Resource)

[Business::GoCardless::Bill](https://metacpan.org/pod/Business::GoCardless::Bill)

[Business::GoCardless::Client](https://metacpan.org/pod/Business::GoCardless::Client)

[Business::GoCardless::Merchant](https://metacpan.org/pod/Business::GoCardless::Merchant)

[Business::GoCardless::Payout](https://metacpan.org/pod/Business::GoCardless::Payout)

[Business::GoCardless::Subscription](https://metacpan.org/pod/Business::GoCardless::Subscription)

[Business::GoCardless::User](https://metacpan.org/pod/Business::GoCardless::User)

[Business::GoCardless::Webhook](https://metacpan.org/pod/Business::GoCardless::Webhook)

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless
