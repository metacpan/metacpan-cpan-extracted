package Business::CPI::Gateway::Test;
# ABSTRACT: Fake gateway

use Moo;

our $VERSION = '0.924'; # VERSION

extends 'Business::CPI::Gateway::Base';
with 'Business::CPI::Role::Gateway::FormCheckout';

sub get_hidden_inputs {
    my ( $self, $info ) = @_;

    my $buyer = $info->{buyer};
    my $cart  = $info->{cart};

    my @hidden_inputs = (
        receiver_email => $self->receiver_id,
        currency       => $self->currency,
        encoding       => $self->form_encoding,
        payment_id     => $info->{payment_id},
        buyer_name     => $buyer->name,
        buyer_email    => $buyer->email,
    );

    my %buyer_extra = (
        address_line1    => 'shipping_address',
        address_line2    => 'shipping_address2',
        address_city     => 'shipping_city',
        address_state    => 'shipping_state',
        address_country  => 'shipping_country',
        address_zip_code => 'shipping_zip',
    );

    for (keys %buyer_extra) {
        if (my $value = $buyer->$_) {
            push @hidden_inputs, ( $buyer_extra{$_} => $value );
        }
    }

    my %cart_extra = (
        discount => 'discount_amount',
        handling => 'handling_amount',
        tax      => 'tax_amount',
    );

    for (keys %cart_extra) {
        if (my $value = $cart->$_) {
            push @hidden_inputs, ( $cart_extra{$_} => $value );
        }
    }

    my $i = 1;

    foreach my $item (@{ $info->{items} }) {
        push @hidden_inputs,
          (
            "item${i}_id"    => $item->id,
            "item${i}_desc"  => $item->description,
            "item${i}_price" => $item->price,
            "item${i}_qty"   => $item->quantity,
          );

        if (my $weight = $item->weight) {
            push @hidden_inputs, ( "item${i}_weight" => $weight * 1000 ); # show in grams
        }

        if (my $ship = $item->shipping) {
            push @hidden_inputs, ( "item${i}_shipping" => $ship );
        }

        if (my $ship = $item->shipping_additional) {
            push @hidden_inputs, ( "item${i}_shipping2" => $ship );
        }

        $i++;
    }

    $i = 1;

    foreach my $receiver (@{ $cart->_receivers }) {
        push @hidden_inputs,
          (
            "receiver${i}_id"      => $receiver->account->gateway_id,
            "receiver${i}_percent" => sprintf("%.2f", 0+$receiver->percent_amount),
          );
        $i++;
    }

    return @hidden_inputs;
}

# TODO
# use SQLite?
# sub get_notification_details {}
# sub query_transactions {}
# sub get_transaction_details {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Gateway::Test - Fake gateway

=head1 VERSION

version 0.924

=head1 DESCRIPTION

Used only for testing. See the t/ directory in this distribution.

=head1 METHODS

=head2 get_hidden_inputs

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
