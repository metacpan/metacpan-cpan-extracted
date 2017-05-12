package Business::CPI::Role::Status;
# ABSTRACT: Status of operations in the gateway
use Moo::Role;
use Types::Standard qw/Bool Str/;

our $VERSION = '0.924'; # VERSION

has is_success => (
    coerce   => Bool->coercion,
    isa      => Bool,
    is       => 'ro',
    required => 1,
);

has is_in_progress => (
    coerce   => Bool->coercion,
    isa      => Bool,
    is       => 'ro',
    required => 1,
);

has is_reverted => (
    coerce   => Bool->coercion,
    isa      => Bool,
    is       => 'ro',
    required => 1,
);

has gateway_name => (
    coerce   => Str->coercion,
    isa      => Str,
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Status - Status of operations in the gateway

=head1 VERSION

version 0.924

=head1 SYNOPSIS

    # example 1: suppose the driver implements the pay() method, which returns
    # a class with the attribute status, which `does` this role.

    my $result = $cart->pay();

    if (!$result->status->is_success) {
        say "Oops. Something went wrong.";
    }
    else {
        say "So far, so good. No errors at this point.";

        if (!$result->status->is_in_progress) {
            say "It's been payed! It's completed!";
        }
        else {
            say "Hold on, the payment is still not confirmed.";
        }
    }

    # example 2: suppose the driver ipmlements the get_cart() method, which
    # also has status attribute, which `does` this role.

    my $cart = $cpi->get_cart(9285210);

    if ($cart->status->is_reverted) {
        say "The buyer got his money back.";
    }
    elsif (!$cart->status->is_success) {
        say "Something went terribly wrong.";
    }
    elsif ($cart->status->is_in_progress) {
        say "It's still being processed, wait a little longer.";
    }
    else {
        say "It's payed and confirmed. Send the buyer his product!";
    }

=head1 DESCRIPTION

Every operation in the gateway might succeed or fail. Maybe it will take a
while until it is actually completed. Maybe it will be done asynchronously. In
any case, we need ways to inform the application of the current status of each
operation. Not only that, we want to keep L<Business::CPI> promises and have
standards for everything that can be standardized.

This role aims to do precisely that, by having three simple and generic boolean
attributes, that can be used for most operations in payment gateways, such as
placing orders, paying them, refunding, and so on.

Some gateways might give out more information than these three attributes
cover. For instance, they might have one status for the moment that the payment
has been received by the gateway, another for when the payment has been
confirmed, and a third status for when the money is actually in the sellers
account. Simply by using these three boolean attributes, the application would
be unable to differentiate between the second and third statuses.

For all situations like that, where gateways implement status that are too
specific, and the application want to treat them individually, the application
will have to handle the L</gateway_name> attribute.

That way, common things will be very easy to deal with, and weird things will
still be possible.

=head1 ATTRIBUTES

=head2 is_success

If true, means the operation hasn't thrown any errors so far. If false,
something has gone wrong. Examples of situations where is_success would be
false `false`:

=over 4

=item The L<order|Business::CPI::Role::Cart> has expired.

=item The credit card was not authorized.

=item The refund was denied.

=back

=head2 is_in_progress

Mainly for gateways that process requests asynchronously, it means the
operation hasn't finished yet. B<Note:> An operation in progress will still
return L</is_success> true, even though it hasn't finished yet! That means that
the application might query the gateway API later, and get a `false`
L</is_success> when the operation has finished.

Examples of successful is_in_progress:

=over 4

=item The gateway has generated a Boleto*, and the buyer still hasn't payed.

=item The credit card is under analysis.

=item The gateway still hasn't gotten confirmation from the bank that the money was transfered.

=back

=head2 is_reverted

The operation, whether successful or not, was reverted. That is, the money that
the buyer sent was returned to them.

=head2 gateway_name

The way the gateway calls this status. Might be needed when the application
needs a finer granularity to handle each status.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
