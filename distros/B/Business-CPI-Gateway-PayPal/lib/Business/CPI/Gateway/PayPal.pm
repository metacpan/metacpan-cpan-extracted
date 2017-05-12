package Business::CPI::Gateway::PayPal;
# ABSTRACT: Business::CPI's PayPal driver

use Moo;
use DateTime;
use DateTime::Format::Strptime;
use Business::CPI::Gateway::PayPal::IPN;
use Business::PayPal::NVP;
use Data::Dumper;
use Carp 'croak';

our $VERSION = '0.905'; # VERSION

extends 'Business::CPI::Gateway::Base';
with 'Business::CPI::Role::Gateway::FormCheckout';

has sandbox => (
    is => 'rw',
    default => sub { 0 },
);

has '+checkout_url' => (
    default => sub {
        my $sandbox = shift->sandbox ? 'sandbox.' : '';
        return "https://www.${sandbox}paypal.com/cgi-bin/webscr";
    },
    lazy => 1,
);

has '+currency' => (
    default => sub { 'USD' },
);

# TODO: make it lazy, and croak if needed
has api_username => (
    is => 'ro',
    required => 0,
);

has api_password => (
    is => 'ro',
    required => 0,
);

has signature    => (
    is => 'ro',
    required => 0,
);

has nvp => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return Business::PayPal::NVP->new(
            test => {
                user => $self->api_username,
                pwd  => $self->api_password,
                sig  => $self->signature,
            },
            live => {
                user => $self->api_username,
                pwd  => $self->api_password,
                sig  => $self->signature,
            },
            branch => $self->sandbox ? 'test' : 'live'
        );
    }
);

has date_format => (
    is => 'ro',
    lazy => 1,
    default => sub {
        DateTime::Format::Strptime->new(
            pattern   => '%Y-%m-%dT%H:%M:%SZ',
            time_zone => 'UTC',
        );
    },
);

sub notify {
    my ( $self, $req ) = @_;

    my $ipn = Business::CPI::Gateway::PayPal::IPN->new(
        query       => $req,
        gateway_url => $self->checkout_url,
    );

    croak 'Invalid IPN request' unless $ipn->is_valid;

    my %vars = %{ $ipn->vars };

    $self->log->info("Received notification $vars{ipn_track_id} for transaction $vars{txn_id}.");

    my $r = {
        payment_id             => $vars{invoice},
        status                 => $self->_interpret_status($vars{payment_status}),
        gateway_transaction_id => $vars{txn_id},
        exchange_rate          => $vars{exchange_rate},
        net_amount             => ($vars{settle_amount} || $vars{mc_gross}) - ($vars{mc_fee} || 0),
        amount                 => $vars{mc_gross},
        fee                    => $vars{mc_fee},
        date                   => $vars{payment_date},
        payer => {
            name  => $vars{first_name} . ' ' . $vars{last_name},
            email => $vars{payer_email},
        }
    };

    if ($self->log->is_debug) {
        $self->log->debug("The notification data is:\n" . Dumper($r));
        $self->log->debug("The request data is:\n" . Dumper($req));
    }

    return $r;
}

sub _interpret_status {
    my ($self, $status) = @_;

    for ($status) {
        /^Completed$/ ||
        /^Processed$/ and return 'completed';

        /^Denied$/    ||
        /^Expired$/   ||
        /^Failed$/    and return 'failed';

        /^Voided$/    ||
        /^Refunded$/  ||
        /^Reversed$/  and return 'refunded';

        /^Pending$/   and return 'processing';
    }

    return 'unknown';
}

sub query_transactions {
    my ($self, $info) = @_;

    my $final_date   = $info->{final_date}   || DateTime->now(time_zone => 'UTC');
    my $initial_date = $info->{initial_date} || $final_date->clone->subtract(days => 30);

    my %search = $self->nvp->send(
        METHOD    => 'TransactionSearch',
        STARTDATE => $initial_date->strftime('%Y-%m-%dT%H:%M:%SZ'),
        ENDDATE   => $final_date->strftime('%Y-%m-%dT%H:%M:%SZ'),
    );

    if ($search{ACK} ne 'Success') {
        croak "Error in the query: " . Dumper(\%search);
    }

    while (my ($k, $v) = each %search) {
        if ($k =~ /^L_TYPE(.*)$/) {
            my $deleted_key = "L_TRANSACTIONID$1";
            if (lc($v) ne 'payment') {
                delete $search{$deleted_key};
            }
        }
    }

    my @transaction_ids = map { $search{$_} } grep { /^L_TRANSACTIONID/ } keys %search;

    my @transactions    = map { $self->get_transaction_details($_) } @transaction_ids;

    return {
        current_page         => 1,
        results_in_this_page => scalar @transaction_ids,
        total_pages          => 1,
        transactions         => \@transactions,
    };
}

sub get_transaction_details {
    my ( $self, $id ) = @_;

    my %details = $self->nvp->send(
        METHOD        => 'GetTransactionDetails',
        TRANSACTIONID => $id,
    );

    if ($details{ACK} ne 'Success') {
        croak "Error in the details fetching: " . Dumper(\%details);
    }

    return {
        payment_id             => $details{INVNUM},
        status                 => lc($details{PAYMENTSTATUS}),
        amount                 => $details{AMT},
        net_amount             => $details{SETTLEAMT},
        tax                    => $details{TAXAMT},
        exchange_rate          => $details{EXCHANGERATE},
        date                   => $self->date_format->parse_datetime( $details{ORDERTIME} ),
        buyer_email            => $details{EMAIL},
        gateway_transaction_id => $id,
    };
}

sub _checkout_form_main_map {
    {
        receiver_id   => 'business',
        currency      => 'currency_code',
        form_encoding => 'charset',
    }
}

sub _checkout_form_item_map {
    my ($self, $i) = @_;

    {
        id          => "item_number_$i",
        description => "item_name_$i",
        price       => "amount_$i",
        quantity    => "quantity_$i",
        weight      => {
            name => "weight_$i",
            coerce => sub { $_[0] }, # think about weight_unit
        },
        shipping            => "shipping_$i",
        shipping_additional => "shipping2_$i",
    }
}

sub _checkout_form_buyer_map {
    {
        email            => 'email',
        address_line1    => 'address1',
        address_line2    => 'address2',
        address_city     => 'city',
        address_state    => 'state',
        address_country  => {
            name => 'country',
            coerce => sub { uc $_[0] },
        },
        address_zip_code => 'zip',
    }
}

sub _checkout_form_cart_map {
    {
        discount => 'discount_amount_cart',
        handling => 'handling_cart',
        tax      => 'tax_cart',
    }
}

around _get_hidden_inputs_for_items => sub {
    my ($orig, $self, $items) = @_;

    my $add_weight_unit = sub {
        for (@$items) {
            return 1 if $_->weight;
        }
        return 0;
    }->();

    my @result = $self->$orig($items);

    if ($add_weight_unit) {
        push @result, ( "weight_unit" => 'kgs' );
    }

    return @result;
};

sub get_hidden_inputs {
    my ($self, $info) = @_;

    return (
        # -- make paypal accept multiple items (cart)
        cmd           => '_ext-enter',
        redirect_cmd  => '_cart',
        upload        => 1,
        # --

        invoice       => $info->{payment_id},
        no_shipping   => $info->{buyer}->address_line1 ? 0 : 1,

        $self->_get_hidden_inputs_main(),
        $self->_get_hidden_inputs_for_buyer($info->{buyer}),
        $self->_get_hidden_inputs_for_items($info->{items}),
        $self->_get_hidden_inputs_for_cart($info->{cart}),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Gateway::PayPal - Business::CPI's PayPal driver

=head1 VERSION

version 0.905

=head1 ATTRIBUTES

=head2 sandbox

Boolean attribute to set whether it's running on sandbox or not. If it is, it
will post the form to the sandbox url in PayPal.

=head2 api_username

=head2 api_password

=head2 signature

=head2 nvp

Business::PayPal::NVP object, built using the api_username, api_password and
signature attributes.

=head2 date_format

DateTime::Format::Strptime object, to format dates in a way PayPal understands.

=head1 METHODS

=head2 notify

Translate IPN information from PayPal to a standard hash, the same way other
Business::CPI gateways do.

=head2 query_transactions

Searches transactions made by this account.

=head2 get_transaction_details

Get more data about a given transaction.

=head2 get_hidden_inputs

Get all the inputs to make a checkout form.

=head1 SPONSORED BY

Aware - L<http://www.aware.com.br>

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 CONTRIBUTORS

=over 4

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Renato CRON <rentocron@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
