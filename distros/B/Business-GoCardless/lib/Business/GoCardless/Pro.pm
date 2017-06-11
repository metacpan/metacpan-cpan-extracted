package Business::GoCardless::Pro;

=head1 NAME

Business::GoCardless::Pro - Perl library for interacting with the GoCardless Pro v2 API
(https://gocardless.com)

=head1 DESCRIPTION

Module for interacting with the GoCardless Pro (v2) API.

B<You should refer to the official gocardless API documentation in conjunction>
B<with this perldoc>, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods. L<https://developer.gocardless.com>, specifically the docs for the
v2 GoCardless API at L<https://developer.gocardless.com/api-reference>.

Note that this module is currently incomplete and limited to being a back
compatiblity wrapper to allow migration from the v1 (Basic) API. The complete
API methods will be added at a later stage (also: patches welcome).

Also note this class also currently inherits from L<Business::GoCardless::Basic>
so has all attributes and methods available on that class (some of which may not
make sense from the context of the Pro API).

=head1 SYNOPSIS

The following examples show instantiating the object and getting a resource
(Payment in this case) to manipulate. For more examples see the t/004_end_to_end_pro.t
script, which can be run against the gocardless sandbox (or even live) endpoint
when given the necessary ENV variables.

    my $GoCardless = Business::GoCardless::Pro->new(
        token           => $your_gocardless_token
        client_details  => {
            base_url       => $gocardless_url, # defaults to https://api.gocardless.com
            webhook_secret => $secret,
        },
    );

    # create URL for a one off payment
    my $new_bill_url = $GoCardless->new_bill_url(
        session_token        => 'foo',
        description          => "Test Payment",
        success_redirect_url => "http://example.com/rflow/confirm?jwt=$jwt",
    );

    # having sent the user to the $new_bill_url and them having complete it,
    # we need to confirm the resource using the details sent by gocardless to
    # the redirect_uri (https://developer.gocardless.com/api-reference/#redirect-flows-complete-a-redirect-flow)
    my $Payment = $GoCardless->confirm_resource(
        redirect_flow_id => $id,
        type             => 'payment', # bill / payment / pre_auth / subscription
        amount           => 0,
        currency         => 'GBP',
    );

    # get a specfic Payment
    $Payment = $GoCardless->payment( $id );

    # cancel the Payment
    $Payment->cancel;

    # too late? maybe we should refund instead (note: needs to be enabled on GoCardless end)
    $Payment->refund;

    # or maybe it failed?
    $Payment->retry if $Payment->failed;

    # get a list of Payment objects (filter optional: https://developer.gocardless.com/#filtering)
    my @payments = $GoCardless->payments( %filter );

    # on any resource object:
    my %data = $Payment->to_hash;
    my $json = $Payment->to_json;

=head1 PAGINATION

Any methods marked as B<pager> have a dual interface, when called in list context
they will return the first 100 resource objects, when called in scalar context they
will return a L<Business::GoCardless::Paginator> object allowing you to iterate
through all the objects:

    # get a list of L<Business::GoCardless::Payment> objects
    # (filter optional: https://developer.gocardless.com/#filtering)
    my @payments = $GoCardless->payments( %filter );

    # or using the Business::GoCardless::Paginator object:
    my $Pager = $GoCardless->payments;

    while( my @payments = $Pager->next ) {
        foreach my $Payment ( @payments ) {
            ...
        }
    }

=cut

use strict;
use warnings;

use Carp qw/ confess /;
use Moo;
extends 'Business::GoCardless';

use Business::GoCardless::Payment;
use Business::GoCardless::RedirectFlow;
use Business::GoCardless::Subscription;
use Business::GoCardless::Customer;
use Business::GoCardless::Webhook::V2;
use Business::GoCardless::Exception;

=head1 ATTRIBUTES

All attributes are inherited from L<Business::GoCardless::Basic>.

=cut

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 2 },
);

=head1 Payment Methods

=head2 payment

Get an individual payment, returns a L<Business::GoCardless::Payment> object:

    my $Payment = $GoCardless->payment( $id );

=head2 payments (B<pager>)

Get a list of Payment objects (%filter is optional)

    my @payments = $GoCardless->payments( %filter );

=head2 create_payment

Create a payment with the passed params

    my $Payment = $GoCardless->create_payment(
        "amount"      => 100,
        "currency"    => "GBP",
        "charge_date" => "2014-05-19",
        "reference"   => "WINEBOX001",
        "metadata"    => {
          "order_dispatch_date" => "2014-05-22"
        },
        "links" => {
          "mandate"   => "MD123"
        }
    );

=cut

sub payment {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payment','payments' );
}

sub payments {
    my ( $self,%filters ) = @_;
    return $self->_list( 'payments',\%filters );
}

sub create_payment {
    my ( $self,%params ) = @_;
    my $data = $self->client->api_post( '/payments',{ payments => { %params } } );

    return Business::GoCardless::Payment->new(
        client => $self->client,
        %{ $data->{payments} }
    );
}

=head1 Subscription Methods

=head2 subscription

Get an individual subscription, returns a L<Business::GoCardless::Subscrption> object:

    my $Subscription = $GoCardless->subscription( $id );

=head2 subscriptions (B<pager>)

Get a list of Subscription objects (%filter is optional)

    my @subscriptions = $GoCardless->subscriptions( %filter );

=cut

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription','subscriptions' );
}

sub subscriptions {
    my ( $self,%filters ) = @_;
    return $self->_list( 'subscriptions',\%filters );
}

=head1 RedirectFlow Methods

See L<Business::GoCardless::RedirectFlow> for more information on RedirectFlow operations.

=head2 pre_authorization

Get an individual redirect flow, returns a L<Business::GoCardless::RedirectFlow> object:

    my $RedirectFlow = $GoCardless->pre_authorization( $id );

=head2 pre_authorizations (B<pager>)

This is meaningless in the v2 API so will throw an exception if called.

=cut

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'RedirectFlow','redirect_flows' );
};

sub pre_authorizations {
    Business::GoCardless::Exception->throw({
        message => "->pre_authorizations is no longer meaningful in the Pro API",
    });
};

=head1 Customer Methods

See L<Business::GoCardless::Customer> for more information on Customer operations.

=head2 customer

Get an individual customer, returns a L<Business::GoCardless::Customer>.

    my $Customer = $GoCardless->customer;

=head2 customers (B<pager>)

Get a list of L<Business::GoCardless::Customer> objects.

    my @customers = $GoCardless->customers;

=cut

sub customer {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Customer','customer' );
}

sub customers {
    my ( $self,%filters ) = @_;
    return $self->_list( 'customers',\%filters );
}

=head1 Webhook Methods

See L<Business::GoCardless::Webhook::V2> for more information on Webhook operations.

=head2 webhook

Get a L<Business::GoCardless::Webhook::V2> object from the data sent to you via a
GoCardless webhook:

    my $Webhook = $GoCardless->webhook( $json_data,$signature );

=cut

sub webhook {
    my ( $self,$data,$signature ) = @_;

    return Business::GoCardless::Webhook::V2->new(
        client     => $self->client,
        json       => $data,
        # load ordering handled by setting _signature rather than signature
        # signature will be set in the json trigger
        _signature => $signature,
    );
}

sub _list {
    my ( $self,$endpoint,$filters ) = @_;

    my $class = {
        payments       => 'Payment',
        redirect_flows => 'RedirectFlow',
        customers      => 'Customer',
        subscriptions  => 'Subscription',
    }->{ $endpoint };

    $filters //= {};

    my $uri = "/$endpoint";

    if ( keys( %{ $filters } ) ) {
        $uri .= '?' . $self->client->normalize_params( $filters );
    }

    my ( $data,$links,$info ) = $self->client->api_get( $uri );

    $class = "Business::GoCardless::$class";
    my @objects = map { $class->new( client => $self->client,%{ $_ } ) }
        @{ $data->{$endpoint} };

    return wantarray ? ( @objects ) : Business::GoCardless::Paginator->new(
        class   => $class,
        client  => $self->client,
        links   => $links,
        info    => $info ? JSON->new->decode( $info ) : {},
        objects => \@objects,
    );
}

################################################################
#
# BACK COMPATIBILITY SECTION FOLLOWS
# the Pro version of the API is built on "redirect flows" when
# using their hosted pages, so we can make it back compatible
#
################################################################

=head1 BACK COMPATIBILITY METHODS

These methods are provided for moving from the v1 (Basic) API with minimal changes
in your application code. See L<Business::GoCardless::Upgrading> for more info.

=head2 new_bill_url

=head2 new_pre_authorization_url

=head2 new_subscription_url

Return a URL for redirecting the user to to complete a direct debit mandate that
will allow you to setup payments. Note the parameters required are slightly different
to those in the L<Business::GoCardless::Basic> module.

See L<https://developer.gocardless.com/api-reference/#redirect-flows-create-a-redirect-flow>
for more information.

    my $url = $GoCardless->new_bill_url(

        # required
        session_token        => $session_token,
        success_redirect_url => $success_callback_url,

        # optional
        scheme               => $direct_debit_scheme
        description          => $description,
        prefilled_customer   => { ... }, # see documentation above
        links                => { ... }, # see documentation above
    );

=cut

sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'bill',%params );
}

sub new_pre_authorization_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'pre_authorization',%params );
}

sub new_subscription_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'subscription',%params );
}

sub _redirect_flow_from_legacy_params {
    my ( $self,$type,%params ) = @_;

    for ( qw/ session_token success_redirect_url / ) {
        $params{$_} // confess( "$_ is required for new_${type}_url (v2)" );
    }

    # we can't just pass through %params as GoCardless will throw an error
    # if it receives any unknown parameters
    return $self->client->_new_redirect_flow_url({
        ( $params{scheme}                       ? ( scheme => $params{scheme} ) : () ),
        ( $params{description} // $params{name} ? ( description => $params{description} // $params{name} ) : () ),
        session_token        => $params{session_token},
        success_redirect_url => $params{success_redirect_url},

        ( $params{prefilled_customer}
            ? (
                prefilled_customer   => { %{ $params{prefilled_customer} } }
            )
            : (
                prefilled_customer   => {
                    address_line1           => $params{user}{billing_address1}        // '',
                    address_line2           => $params{user}{billing_address2}        // '',
                    address_line3           => $params{user}{billing_address3}        // '',
                    city                    => $params{user}{city}                    // '',
                    company_name            => $params{user}{company_name}            // '',
                    country_code            => $params{user}{country_code}            // '',
                    email                   => $params{user}{email}                   // '',
                    family_name             => $params{user}{last_name}               // '',
                    given_name              => $params{user}{given_name}              // '',
                    language                => $params{user}{language}                // '',
                    postal_code             => $params{user}{billing_postcode}        // '',
                    region                  => $params{user}{region}                  // '',
                    swedish_identity_number => $params{user}{swedish_identity_number} // '',
                },
            )
        ),

        (
            $params{links}{creditor}
                ? ( links => { creditor => $params{links}{creditor} } )
                : ()
        ),
    });
}

=head2 confirm_resource

After a user completes the form in the redirect flow (using a URL generated from
one of the new_.*?url methods above) GoCardless will redirect them back to the
success_redirect_url with a redirect_flow_id, at which point you can call this
method to confirm the mandate and set up a one off payment, subscription, etc

The object returned will depend on the C<type> parameter passed to the method

    my $Payment = $GoCardless->confirm_resource(

        # required 
        redirect_flow_id => $redirect_flow_id,
        type             => 'payment', # one of bill, payment, pre_auth, subscription
        amount           => 0,
        currency         => 'GBP',

        # required in the case of type being "subscription"
        interval_unit    =>
        interval         =>
        start_at         =>
    );

=cut

# BACK COMPATIBILITY method, in which we (try to) return the correct object for
# the required type as this is how the v1 API works
sub confirm_resource {
    my ( $self,%params ) = @_;

    for ( qw/ redirect_flow_id type amount currency / ) {
        $params{$_} // confess( "$_ is required for confirm_resource (v2)" );
    }

    my $r_flow_id = $params{redirect_flow_id};
    my $type      = $params{type};
    my $amount    = $params{amount};
    my $currency  = $params{currency};
    my $int_unit  = $params{interval_unit};
    my $interval  = $params{interval};
    my $start_at  = $params{start_at};

    if ( my $RedirectFlow = $self->client->_confirm_redirect_flow( $r_flow_id ) ) {

        # now we have a confirmed redirect flow object we can create the
        # payment, subscription, whatever
        if ( $type =~ /bill|payment/i ) {

            # Bill -> Payment
            my $post_data = {
                payments => {
                    amount   => $amount,
                    currency => $currency,
                    links    => {
                        mandate => $RedirectFlow->links->{mandate},
                    },
                },
            };

            my $data = $self->client->api_post( "/payments",$post_data );

            return Business::GoCardless::Payment->new(
                client => $self->client,
                %{ $data->{payments} },
            );

        } elsif ( $type =~ /pre_auth/i ) {

            # a pre authorization is, effectively, a redirect flow
            return $RedirectFlow;

        } elsif ( $type =~ /subscription/i ) {

            my $post_data = {
                subscriptions => {
                    amount        => $amount,
                    currency      => $currency,
                    interval_unit => $int_unit,
                    interval      => $interval,
                    start_date    => $start_at,
                    links => {
                        mandate => $RedirectFlow->links->{mandate},
                    },
                },
            };

            my $data = $self->client->api_post( "/subscriptions",$post_data );

            return Business::GoCardless::Subscription->new(
                client => $self->client,
                %{ $data->{subscriptions} },
            );
        }

        # don't know what to do, complain
        Business::GoCardless::Exception->throw({
            message => "Unkown type ($type) in ->confirm_resource",
        });
    }

    Business::GoCardless::Exception->throw({
        message => "Failed to get RedirectFlow for $r_flow_id",
    });
}

sub users { shift->customers( @_ ); }

=head1 SEE ALSO

L<Business::GoCardless>

L<Business::GoCardless::Resource>

L<Business::GoCardless::Payment>

L<Business::GoCardless::Client>

L<Business::GoCardless::Subscription>

L<Business::GoCardless::User>

L<Business::GoCardless::Webhook::V2>

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
