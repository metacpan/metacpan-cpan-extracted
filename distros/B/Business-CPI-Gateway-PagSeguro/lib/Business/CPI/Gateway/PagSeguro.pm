package Business::CPI::Gateway::PagSeguro;
# ABSTRACT: Business::CPI's PagSeguro driver

use Moo;
use XML::LibXML;
use Carp;
use LWP::Simple ();
use URI;
use URI::QueryParam;
use DateTime;
use Locale::Country ();
use Data::Dumper;

extends 'Business::CPI::Gateway::Base';
with 'Business::CPI::Role::Gateway::FormCheckout';

our $VERSION = '0.904'; # VERSION

has '+checkout_url' => (
    default => sub { 'https://pagseguro.uol.com.br/v2/checkout/payment.html' },
);

has '+currency' => (
    default => sub { 'BRL' },
);

has base_url => (
    is => 'ro',
    default => sub { 'https://ws.pagseguro.uol.com.br/v2' },
);

has token => (
    is  => 'ro',
);

sub get_notifications_url {
    my ($self, $code) = @_;

    return $self->_build_uri("/transactions/notifications/$code");
}

sub get_transaction_details_url {
    my ($self, $code) = @_;

    return $self->_build_uri("/transactions/$code");
}

sub get_transaction_query_url {
    my ($self, $info) = @_;

    $info ||= {};

    my $final_date   = $info->{final_date}   || DateTime->now(time_zone => 'local'); # XXX: really local?
    my $initial_date = $info->{initial_date} || $final_date->clone->subtract(days => 30);

    my $new_info = {
        initialDate    => $initial_date->strftime('%Y-%m-%dT%H:%M'),
        finalDate      => $final_date->strftime('%Y-%m-%dT%H:%M'),
        page           => $info->{page} || 1,
        maxPageResults => $info->{rows} || 1000,
    };

    return $self->_build_uri('/transactions', $new_info);
}

sub query_transactions { goto \&get_and_parse_transactions }

sub get_and_parse_notification {
    my ($self, $code) = @_;

    my $xml = $self->_load_xml_from_url(
        $self->get_notifications_url($code)
    );

    if ($self->log->is_debug) {
        $self->log->debug("The notification we received was:\n" . Dumper($xml));
    }

    return $self->_parse_transaction($xml);
}

sub notify {
    my ($self, $req) = @_;

    if ($req->params->{notificationType} eq 'transaction') {
        my $code = $req->params->{notificationCode};

        $self->log->info("Received notification for $code");

        my $result = $self->get_and_parse_notification( $code );

        if ($self->log->is_debug) {
            $self->log->debug("The notification we're returning is " . Dumper($result));
        }

        return $result;
    }
}

sub get_and_parse_transactions {
    my ($self, $info) = @_;

    my $xml = $self->_load_xml_from_url(
        $self->get_transaction_query_url( $info )
    );

    my $results_in_this_page = $xml->getChildrenByTagName('resultsInThisPage')->string_value;

    my @transactions = $results_in_this_page
                     ? $xml->getChildrenByTagName('transactions')->get_node(1)->getChildrenByTagName('transaction')
                     : ()
                     ;

    return {
        current_page         => $xml->getChildrenByTagName('currentPage')->string_value,
        results_in_this_page => $results_in_this_page,
        total_pages          => $xml->getChildrenByTagName('totalPages')->string_value,
        transactions         => [
            map { $self->get_transaction_details( $_ ) }
            map { $_->getChildrenByTagName('code')->string_value } @transactions
        ],
    };
}

sub get_transaction_details {
    my ($self, $code) = @_;

    my $xml = $self->_load_xml_from_url(
        $self->get_transaction_details_url( $code )
    );

    my $result = $self->_parse_transaction($xml);
    $result->{buyer_email} = $xml->getChildrenByTagName('sender')->get_node(1)->getChildrenByTagName('email')->string_value;

    return $result;
}

sub _parse_transaction {
    my ($self, $xml) = @_;

    my $date   = $xml->getChildrenByTagName('date')->string_value;
    my $ref    = $xml->getChildrenByTagName('reference')->string_value;
    my $status = $xml->getChildrenByTagName('status')->string_value;
    my $amount = $xml->getChildrenByTagName('grossAmount')->string_value;
    my $net    = $xml->getChildrenByTagName('netAmount')->string_value;
    my $fee    = $xml->getChildrenByTagName('feeAmount')->string_value;
    my $code   = $xml->getChildrenByTagName('code')->string_value;
    my $payer  = $xml->getChildrenByTagName('sender')->get_node(1)->getChildrenByTagName('name')->string_value;

    return {
        payment_id             => $ref,
        gateway_transaction_id => $code,
        status                 => $self->_interpret_status($status),
        amount                 => $amount,
        date                   => $date,
        net_amount             => $net,
        fee                    => $fee,
        exchange_rate          => 0,
        payer => {
            name => $payer,
        },
    };
}

sub _load_xml_from_url {
    my ($self, $url) = @_;

    return XML::LibXML->load_xml(
        string => LWP::Simple::get( $url )
    )->firstChild();
}

sub _build_uri {
    my ($self, $path, $info) = @_;

    $info ||= {};

    $info->{email} = $self->receiver_id;
    $info->{token} = $self->token;

    my $uri = URI->new($self->base_url . $path);

    while (my ($k, $v) = each %$info) {
        $uri->query_param($k, $v);
    }

    return $uri->as_string;
}

sub _interpret_status {
    my ($self, $status) = @_;

    $status = int($status || 0);

    # 1: aguardando pagamento
    # 2: em análise
    # 3: paga
    # 4: disponível
    # 5: em disputa
    # 6: devolvida
    # 7: cancelada

    my @status_codes = ('unknown');
    @status_codes[1,2,5] = ('processing') x 3;
    @status_codes[3,4]   = ('completed') x 2;
    $status_codes[6]     = 'refunded';
    $status_codes[7]     = 'failed';

    if ($status > 7) {
        return 'unknown';
    }

    return $status_codes[$status];
}

sub _checkout_form_main_map {
    return {
        receiver_id   => 'receiverEmail',
        currency      => 'currency',
        form_encoding => 'encoding',
    };
}

sub _checkout_form_item_map {
    my ($self, $number) = @_;

    return {
        id          => "itemId$number",
        description => "itemDescription$number",
        price       => "itemAmount$number",
        quantity    => "itemQuantity$number",
        weight      => {
            name   => "itemWeight$number",
            coerce => sub { $_[0] * 1000 },
        },
        shipping    => "itemShippingCost$number"
    };
}

sub _checkout_form_buyer_map {
    return {
        name               => 'senderName',
        email              => 'senderEmail',
        address_complement => 'shippingAddressComplement',
        address_district   => 'shippingAddressDistrict',
        address_street     => 'shippingAddressStreet',
        address_number     => 'shippingAddressNumber',
        address_city       => 'shippingAddressCity',
        address_state      => 'shippingAddressState',
        address_zip_code   => 'shippingAddressPostalCode',
        address_country    => {
            name => 'shippingAddressCountry',
            coerce => sub {
                uc(
                    Locale::Country::country_code2code(
                        $_[0], 'alpha-2', 'alpha-3'
                    )
                )
            },
        },
    };
}

sub _get_hidden_inputs_for_cart {
    my ($self, $cart) = @_;

    my $handling = $cart->handling || 0;
    my $discount = $cart->discount || 0;
    my $tax      = $cart->tax      || 0;

    my $extra_amount = $tax + $handling - $discount;

    if ($extra_amount) {
        return ( extraAmount => sprintf( "%.2f", $extra_amount ) );
    }
    return ();
}

sub get_hidden_inputs {
    my ($self, $info) = @_;

    return (
        reference => $info->{payment_id},

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

Business::CPI::Gateway::PagSeguro - Business::CPI's PagSeguro driver

=head1 VERSION

version 0.904

=head1 ATTRIBUTES

=head2 token

The token provided by PagSeguro

=head2 base_url

The url for PagSeguro API. Not to be confused with the checkout url, this is
just for the API.

=head1 METHODS

=head2 get_notifications_url

Reader for the notifications URL in PagSeguro's API. This uses the base_url
attribute.

=head2 get_transaction_details_url

Reader for the transaction details URL in PagSeguro's API. This uses the
base_url attribute.

=head2 get_transaction_query_url

Reader for the transaction query URL in PagSeguro's API. This uses the base_url
attribute.

=head2 get_and_parse_notification

Gets the url from L</get_notifications_url>, and loads the XML from there.
Returns a parsed standard Business::CPI hash.

=head2 get_and_parse_transactions

=head2 get_transaction_details

=head2 query_transactions

Alias for L</get_and_parse_transactions> to maintain compatibility with other
Business::CPI modules.

=head2 notify

=head2 get_hidden_inputs

=head1 SPONSORED BY

Aware - L<http://www.aware.com.br>

=head1 SEE ALSO

L<Business::CPI::Gateway::Base>

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 CONTRIBUTOR

Renato CRON <rentocron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
