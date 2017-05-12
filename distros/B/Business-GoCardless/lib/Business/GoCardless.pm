package Business::GoCardless;

=head1 NAME

Business::GoCardless - Perl library for interacting with the GoCardless Basic v1 API
(https://gocardless.com)

=for html
<a href='https://travis-ci.org/Humanstate/business-gocardless?branch=master'><img src='https://travis-ci.org/Humanstate/business-gocardless.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/business-gocardless?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-gocardless/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.16

=head1 DESCRIPTION

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

use Moo;
with 'Business::GoCardless::Version';

use Carp qw/ confess /;

use Business::GoCardless::Client;
use Business::GoCardless::Webhook;

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

=cut

has token => (
    is       => 'ro',
    required => 1,
);

has client_details => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a hashref" )
            if ref( $_[0] ) ne 'HASH';
    },
    required => 0,
    lazy     => 1,
    default  => sub { return {} },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::GoCardless::Client" )
            if ref $_[0] ne 'Business::GoCardless::Client'
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        return Business::GoCardless::Client->new(
            %{ $self->client_details },
            token => $self->token,
        );
    },
);

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

=cut

sub confirm_resource {
    my ( $self,%params ) = @_;
    return $self->client->_confirm_resource( \%params );
}

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

=cut

sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_bill_url( \%params );
}

sub bill {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Bill' );
}

sub bills {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->bills( \%filters );
}

=head1 Merchant Methods

See L<Business::GoCardless::Merchant> for more information on Merchant operations.

=head2 merchant

Get object that represents you (Merchant)

    my $Merchant = $GoCardless->merchant;

=head2 payouts (B<pager>)

Get a list of L<Business::GoCardless::Payout> objects.

    my @payouts = $GoCardless->payouts;

=cut

sub merchant {
    my ( $self,$merchant_id ) = @_;

    $merchant_id //= $self->client->merchant_id;
    return Business::GoCardless::Merchant->new(
        client => $self->client,
        id     => $merchant_id
    );
}

sub payouts {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->payouts( \%filters );
}

=head1 Payout Methods

See L<Business::GoCardless::Payout> for more information on Payout operations.

=head2 payout

Get a L<Business::GoCardless::Payout> object for a specific payout.

    my $Payout = $GoCardless->payout( $id );

=cut

sub payout {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payout' );
}

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

=cut

sub new_pre_authorization_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_pre_authorization_url( \%params );
}

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'PreAuthorization' );
}

sub pre_authorizations {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->pre_authorizations( \%filters );
}

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

=cut

sub new_subscription_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_subscription_url( \%params );
}

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription' );
}

sub subscriptions {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->subscriptions( \%filters );
}

=head1 User Methods

See L<Business::GoCardless::User> for more information on User operations.

=head2 users (B<pager>)

Get a list of L<Business::GoCardless::User> objects.

    my @users = $GoCardless->users;

=cut

sub users {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->users( \%filters );
}

=head1 Webhook Methods

See L<Business::GoCardless::Webhook> for more information on Webhook operations.

=head2 webhook

Get a L<Business::GoCardless::Webhook> object from the data sent to you via a
GoCardless webhook:

    my $Webhook = $GoCardless->webhook( $json_data );

=cut

sub webhook {
    my ( $self,$data ) = @_;

    return Business::GoCardless::Webhook->new(
        client => $self->client,
        json   => $data,
    );
}

sub _generic_find_obj {
    my ( $self,$id,$class ) = @_;
    $class = "Business::GoCardless::$class";
    my $obj = $class->new(
        id     => $id,
        client => $self->client
    );
    return $obj->find_with_client;
}

=head1 SEE ALSO

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

# vim: ts=4:sw=4:et
