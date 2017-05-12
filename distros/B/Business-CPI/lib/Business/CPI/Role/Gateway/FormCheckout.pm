package Business::CPI::Role::Gateway::FormCheckout;
# ABSTRACT: Provide a checkout with simple HTML forms
use utf8;
use Moo::Role;
use HTML::Element;
use Data::Dumper;

our $VERSION = '0.924'; # VERSION

requires 'map_object', 'get_hidden_inputs', 'checkout_url';

has checkout_form_http_method => (
    is => 'ro',
    default => sub { 'post' },
);

has checkout_form_submit_name => (
    is => 'ro',
    default => sub { 'submit' },
);

has checkout_form_submit_value => (
    is => 'ro',
    default => sub { '' },
);

has checkout_form_submit_image => (
    is => 'ro',
    default => sub { '' },
);

has form_encoding => (
    is      => 'ro',
    # TODO: use Encode::find_encoding()
    default => sub { 'UTF-8' },
);

sub _get_hidden_inputs_for_cart {
    my ($self, $cart) = @_;

    return $self->map_object( $self->_checkout_form_cart_map, $cart );
}

sub _get_hidden_inputs_for_buyer {
    my ($self, $buyer) = @_;

    return $self->map_object( $self->_checkout_form_buyer_map, $buyer );
}

sub _get_hidden_inputs_for_items {
    my ($self, $items) = @_;
    my @result;
    my $i = 1;

    for my $item (@$items) {
        push @result,
          $self->map_object( $self->_checkout_form_item_map( $i++ ), $item );
    }

    return @result;
}

sub _get_hidden_inputs_main {
    my $self = shift;

    return $self->map_object( $self->_checkout_form_main_map, $self );
}

sub get_form {
    my ($self, $info) = @_;

    $self->log->info("Get form for payment " . $info->{payment_id});

    my @hidden_inputs = $self->get_hidden_inputs($info);

    if ($self->log->is_debug) {
        $self->log->debug("Building form with inputs: " . Dumper(\@hidden_inputs));
        $self->log->debug("form action => " . $self->checkout_url);
        $self->log->debug("form method => " . $self->checkout_form_http_method);
    }

    my $form = HTML::Element->new(
        'form',
        action => $self->checkout_url,
        method => $self->checkout_form_http_method,
    );

    while (@hidden_inputs) {
        $form->push_content(
            HTML::Element->new(
                'input',
                type  => 'hidden',
                value => pop @hidden_inputs,
                name  => pop @hidden_inputs
            )
        );
    }

    my %submit = (
        name  => $self->checkout_form_submit_name,
        type  => 'submit',
    );

    if (my $value = $self->checkout_form_submit_value) {
        $submit{value} = $value;
    }

    if (my $src = $self->checkout_form_submit_image) {
        $submit{src}  = $src;
        $submit{type} = 'image';
    }

    $form->push_content(
        HTML::Element->new( 'input', %submit )
    );

    return $form;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Gateway::FormCheckout - Provide a checkout with simple HTML forms

=head1 VERSION

version 0.924

=head1 ATTRIBUTES

=head2 form_encoding

Defaults to UTF-8.

=head2 checkout_form_http_method

Defaults to post.

=head2 checkout_form_submit_name

Defaults to submit.

=head2 checkout_form_submit_value

Defaults to ''.

=head2 checkout_form_submit_image

If set, makes the submit button become an image. Set this to the URL of the
image you want to display in the checkout button. Defaults to '' (i.e., no
image, default brower submit button).

=head1 METHODS

=head2 get_form

Get the form to checkout. Use L<Business::CPI::Role::Cart/get_form>, don't use
this method directly.

=head2 get_hidden_inputs

This method is called when building the checkout form. It will return a hashref
with the field names and field values for the form. This way the gateway will
implement only this method, while the rest of the form will be built by this
class.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
