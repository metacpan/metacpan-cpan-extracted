package Business::GoCardless::Basic;

=head1 NAME

Business::GoCardless - Perl library for interacting with the GoCardless Basic v1 API
(https://gocardless.com)

=head1 DESCRIPTION

Module for interacting with the GoCardless Basic (v1) API. Please note this
module is B<only> compatible with the Basic v1 GoCardless API,
which GoCardless are now calling "The Legacy GoCardless API". If you wish to
use the Pro (v2) API you should use the L<Business::GoCardless::Pro> module.

B<You should refer to the official gocardless API documentation in conjunction>
B<with this perldoc>, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods. L<https://developer.gocardless.com>, specifically the docs for the
v1 GoCardless API at L<https://developer.gocardless.com/legacy>.

=head1 SYNOPSIS

The following examples show instantiating the object and getting a resource
(Bill in this case) to manipulate. For more examples see the t/002_end_to_end.t
script, which can be run against the gocardless sandbox (or even live) endpoint
when given the necessary ENV variables.

    my $GoCardless = Business::GoCardless::Basic->new(
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

=head1 ERROR HANDLING

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

=head1 PAGINATION

Any methods marked as B<pager> have a dual interface, when called in list context
they will return the first 100 resource objects, when called in scalar context they
will return a L<Business::GoCardless::Paginator> object allowing you to iterate
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

=cut

use strict;
use warnings;

# just extending Business::GoCardless here for back compat until
# the legacy API is switched off, at which point we can remove
# all of that code and this perldoc
use Moo;
extends 'Business::GoCardless';

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 1 },
);


=head1 ATTRIBUTES

=head2 token

Your gocardless API token, this attribute is required.

=head2 client_details

Hash of gocardless client details, passed to L<Business::GoCardless::Client>.

    base_url    => $gocardless_url, # defaults to https://gocardless.com
    app_id      => $your_gocardless_app_id,
    app_secret  => $your_gocardless_app_secret,
    merchant_id => $your_gocardless_merchant_id,

=head2 client

The client object, defaults to L<Business::GoCardless::Client>.

=head1 Common Methods

Methods not tied to any particular resource.

=head2 confirm_resource

Confirm a resource.

    my $Bill = $GoCardless->confirm_resource(
        resource_uri  => $uri,
        resource_type => 'bill',
        resource_id   => $bill_id,
        signature     => $signature,
        state         => "some_state_data",
    );

=head1 Bill Methods

See L<Business::GoCardless::Bill> for more information on Bill operations.

=head2 new_bill_url

Create a URL for generating a one off bill:

    my $new_bill_url = $GoCardless->new_bill_url(
        amount => 100,
    );

=head2 bill

Get a L<Business::GoCardless::Bill> object for a specific bill.

    my $Bill = $GoCardless->bill( $id );

=head2 bills (B<pager>)

Get a list of Bill objects (%filter is optional).

    my @bills = $GoCardless->bills( %filter );

=head1 Merchant Methods

See L<Business::GoCardless::Merchant> for more information on Merchant operations.

=head2 merchant

Get object that represents you (Merchant)

    my $Merchant = $GoCardless->merchant;

=head2 payouts (B<pager>)

Get a list of L<Business::GoCardless::Payout> objects.

    my @payouts = $GoCardless->payouts;

=head1 Payout Methods

See L<Business::GoCardless::Payout> for more information on Payout operations.

=head2 payout

Get a L<Business::GoCardless::Payout> object for a specific payout.

    my $Payout = $GoCardless->payout( $id );

=head1 PreAuthorization Methods

See L<Business::GoCardless::PreAuthorization> for more information on PreAuthorization operations.

=head2 new_pre_authorization_url

Create a URL for generating a pre_authorization.

    my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
        max_amount      => 100,
        interval_length => 10,
        interval_unit   => 'day',
    );

=head2 pre_authorization

Get a L<Business::GoCardless::PreAuthorization> object for a specific pre_authorization.

    my $PreAuth = $GoCardless->pre_authorization( $id );

=head2 pre_authorizations (B<pager>)

Get a list of L<Business::GoCardless::PreAuthorization> objects.

    my @pre_auths = $GoCardless->pre_authorizations;

=head1 Subscription Methods

See L<Business::GoCardless::Subscription> for more information on Subscription operations.

=head2 new_subscription_url

Create a URL for generating a subscription.

    my $new_pre_auth_url = $GoCardless->new_subscription_url(
        amount          => 100,
        interval_length => 1,
        interval_unit   => 'month',
    );

=head2 subscription

Get a L<Business::GoCardless::Subscription> object for a specific subscription.

    my $Subscription = $GoCardless->subscription( $id );

=head2 subscriptions (B<pager>)

Get a list of L<Business::GoCardless::Subscription> objects.

    my @subs = $GoCardless->subscriptions;

=head1 User Methods

See L<Business::GoCardless::User> for more information on User operations.

=head2 users (B<pager>)

Get a list of L<Business::GoCardless::User> objects.

    my @users = $GoCardless->users;

=head1 Webhook Methods

See L<Business::GoCardless::Webhook> for more information on Webhook operations.

=head2 webhook

Get a L<Business::GoCardless::Webhook> object from the data sent to you via a
GoCardless webhook:

    my $Webhook = $GoCardless->webhook( $json_data );

=head1 SEE ALSO

L<Business::GoCardless>

L<Business::GoCardless::Pro>

L<Business::GoCardless::Resource>

L<Business::GoCardless::Bill>

L<Business::GoCardless::Client>

L<Business::GoCardless::Merchant>

L<Business::GoCardless::Payout>

L<Business::GoCardless::Subscription>

L<Business::GoCardless::User>

L<Business::GoCardless::Webhook>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;
