package Business::CPI::Gateway::Base;
# ABSTRACT: Father of all gateways
use Moo;
use Locale::Currency ();
use Data::Dumper;
use Carp qw/croak/;
use Business::CPI::Util::Types qw/UserAgent HTTPResponse/;
use Types::Standard qw/Maybe/;
use LWP::UserAgent;

with 'Business::CPI::Role::Gateway::Base';

our $VERSION = '0.924'; # VERSION

has receiver_id => (
    is => 'ro',
);

has checkout_url => (
    is => 'rw',
);

has checkout_with_token => (
    is => 'ro',
    default => sub { 0 },
);

has currency => (
    isa => sub {
        my $curr = uc($_[0]);

        for (Locale::Currency::all_currency_codes()) {
            return 1 if $curr eq uc($_);
        }

        die "Must be a valid currency code";
    },
    coerce => sub { uc $_[0] },
    is => 'ro',
);

has user_agent => (
    is => 'rwp',
    isa => UserAgent,
    lazy => 1,
    builder => '_build_user_agent',
);

has most_recent_request => (
    is => 'rwp',
    isa => Maybe[HTTPResponse],
);

has error => ( is => 'rwp' );

sub new_account {
    my ($self, $account) = @_;

    return $self->account_class->new(
        _gateway => $self,
        %$account
    );
}

sub new_cart {
    my ( $self, $info ) = @_;

    if ($self->log->is_debug) {
        $self->log->debug("Building a cart with: " . Dumper($info));
    }

    my @items     = @{ delete $info->{items}     || [] };
    my @receivers = @{ delete $info->{receivers} || [] };

    my $buyer_class = $self->buyer_class;
    my $cart_class  = $self->cart_class;

    # We might be using a more generic Account class
    if ($buyer_class->does('Business::CPI::Role::Account')) {
        $info->{buyer}{_gateway} = $self;
    }

    $self->log->debug(
        "Loaded buyer class $buyer_class and cart class $cart_class."
    );

    my $buyer = $buyer_class->new( delete $info->{buyer} );

    $self->log->info("Built cart for buyer " . $buyer->email);

    my $cart = $cart_class->new(
        _gateway => $self,
        buyer    => $buyer,
        %$info,
    );

    for (@items) {
        $cart->add_item($_);
    }

    for (@receivers) {
        $cart->add_receiver($_);
    }

    return $cart;
}

sub map_object {
    my ($self, $map, $obj) = @_;

    my @result;

    while (my ($bcpi_key, $gtw_key) = each %$map) {
        my $value = $obj->$bcpi_key;
        next unless $value;

        my $name = $gtw_key;

        if (ref $gtw_key) {
            $name  = $gtw_key->{name};
            $value = $gtw_key->{coerce}->($name);
        }

        push @result, ( $name, $value );
    }

    return @result;
}

sub get_notification_details { shift->_unimplemented }

sub query_transactions { shift->_unimplemented }

sub get_transaction_details { shift->_unimplemented }

sub notify { shift->_unimplemented }

sub get_checkout_code { shift->_unimplemented }

sub _unimplemented {
    my $self = shift;
    die "Not implemented.";
}

sub _build_user_agent {
    my ($self) = @_;

    my $class_name = ref $self;
    my $version = eval { $self->VERSION } || 'devel';

    return LWP::UserAgent->new(agent => "$class_name/$version");
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = $self->$orig(@_);

    if ($args->{receiver_email}) {
        croak 'receiver_email attribute has been removed - use receiver_id instead';
    }

    return $args;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Gateway::Base - Father of all gateways

=head1 VERSION

version 0.924

=head1 ATTRIBUTES

=head2 driver_name

The name of the driver for this gateway. This is built automatically, but can
be customized.

Example: for C<Business::CPI::Gateway::TestGateway>, the driver name will be
C<TestGateway>.

=head2 log

Provide a logger to the gateway. It's the user's responsibility to configure
the logger. By default, nothing is logged. You could set this to a
L<Log::Log4perl> object, for instance, to get full logging.

=head2 item_class

The class for the items (products) being purchased. Defaults to
Business::CPI::${driver_name}::Item if it exists, or
L<Business::CPI::Base::Item> otherwise.

=head2 cart_class

The class for the shopping cart (the complete order). Defaults to
Business::CPI::${driver_name}::Cart if it exists, or
L<Business::CPI::Base::Cart> otherwise.

=head2 buyer_class

The class for the buyer (the sender). Defaults to
Business::CPI::${driver_name}::Buyer if it exists, or
L<Business::CPI::Base::Buyer> otherwise.

=head2 account_class

The class for the accounts. Defaults to Business::CPI::${driver_name}::Account
if it exists, or L<Business::CPI::Base::Account> otherwise.

=head2 account_address_class

The class for the addresses for the accounts. Defaults to
Business::CPI::${driver_name}::Account::Address if it exists, or
L<Business::CPI::Base::Account::Address> otherwise.

=head2 account_business_class

The class for the business information of accounts. Defaults to
Business::CPI::${driver_name}::Account::Business if it exists, or
L<Business::CPI::Base::Account::Business> otherwise.

=head2 receiver_id

ID, login or e-mail of the business owner. The way the gateway uniquely
identifies the account owner.

=head2 currency

Currency code, such as BRL, EUR, USD, etc.

=head2 notification_url

The url for the gateway to postback, notifying payment changes.

=head2 return_url

The url for the customer to return to, after they finished the payment.

=head2 checkout_with_token

Boolean attribute to determine whether the form will hold the entire cart, or
it will use the payment token generated for it. Defaults to false.

=head2 checkout_url

The url the application will post the form to. Defined by the gateway.

=head2 user_agent

User agent object (using L<LWP::UserAgent>'s API) to make requests to the gateway.

=head2 error

Whenever an exception is thrown, this attribute will also hold the exception
object. This is because $@ may be overwritten before the exception is handled.

So one can use:

    try {
        # do something that will trigger an exception
        $cpi->get_cart('something that doesnt exist');
    }
    catch {
        if ($cpi->error->type eq 'resource_not_found') {
            warn "Oops, it doesn't exist.";
        }

        # $cpi->error is the same as $_ and $_[0], unless someone messed up
        # with $@, e.g., using $SIG{__DIE__} or something nasty like that. In
        # that case, $_ is lost, but $cpi->error is safe.
    }

=head2 most_recent_request

Whenever a request is made to the gateway, this attribute will hold the
HTTP::Response object returned by the request.

B<Note:> this is meant to be used for custom logging in the application.
Usually, it's better to keep all the request-related details handled by
Business::CPI, and abstract all the low-level details to the user. That
includes logging, for the most part. The object returned by each method
implemented by Business::CPI should be enough in most cases.

If you find yourself having to use this attribute too much, it probably means
that gateway's Business::CPI driver is not doing what it should.

=head1 METHODS

=head2 new_cart

Creates a new L<Business::CPI::Role::Cart> connected to this gateway.

=head2 new_account

Creates a new instance of an account. In general, you shouldn't need to use
this, except for testing. Use C<create_account>, instead, if your driver
provides it.

=head2 get_checkout_code

Generates a payment token for a given cart. Do not call this method directly.
Instead, see L<Business::CPI::Role::Cart/get_checkout_code>.

=head2 get_notification_details

Get the payment notification (such as PayPal's IPN), and return a hashref with
the details.

=head2 query_transactions

Search past transactions.

=head2 get_transaction_details

Get more details about a given transaction.

=head2 notify

This is supposed to be called when the gateway sends a notification about a
payment status change to the application. Receives the request as a parameter
(in a CGI-compatible format), and returns data about the payment. The format is
still under discussion, and is soon to be documented.

=head2 map_object

Helper method for get_hidden_inputs to translate between Business::CPI and the
gateway, using methods like checkout_form_items_map, checkout_form_buyer_map,
etc.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
