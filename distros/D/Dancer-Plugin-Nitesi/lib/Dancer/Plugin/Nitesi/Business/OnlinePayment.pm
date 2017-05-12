package Dancer::Plugin::Nitesi::Business::OnlinePayment;

use Business::OnlinePayment 3.02;
use Dancer ':syntax';
use Moo;

=head1 NAME

Dancer::Plugin::Nitesi::Business::OnlinePayment - Nitesi wrapper for Business:OnlinePayment

=head1 CONFIGURATION

Configuration for AuthorizeNet provider:

  plugins:
    Nitesi:
      Payment:
        default_provider: AuthorizeNet
        providers:
          AuthorizeNet:
            login: <API Login ID>
            password: <Transaction Key>

If you use a test account, please add the following
parameters:

            test_transaction: 1
            server: test.authorize.net

=head1 ATTRIBUTES

=head2 provider

Payment provider.

=cut

has provider => (
    is => 'rwp',
);

=head2 provider_args

Payment provider settings, like login and password.

=cut.

has provider_args => (
    is => 'rwp',
);

=head2 is_success

True if the payment was successful, false otherwise.

=cut

has is_success => (
    is => 'rwp',
);

=head2 authorization

Returns authorization code from provider after a successful
payment.

=cut

has authorization => (
    is => 'rwp',
);

=head2 order_number

Returns unique order number from provider after a successful
payment.

=cut

has order_number => (
    is => 'rwp',
);

=head2 error_message

Returns error message in case of payment failure.

=cut

has error_message => (
    is => 'rwp',
);

sub BUILDARGS {
    my ( $class, @args ) = @_;
    my ( %params );

    # first argument is the provider
    $params{provider} = shift @args;
    $params{provider_args} = {@args};

    return \%params;
}

=head1 METHODS

=head2 charge

Performs charge transaction with payment provider.

=cut

sub charge {
    my ( $self, %args ) = @_;
    my ( $provider_settings, $bop_object );

    # reset values
    $self->_set_is_success(0);
    $self->_set_authorization('');
    $self->_set_order_number('');
    $self->_set_error_message('');

    $provider_settings = $self->provider_args;

    $bop_object = Business::OnlinePayment->new($self->provider, %$provider_settings);

	if ($provider_settings->{server}) {
		$bop_object->server( $provider_settings->{server} );
	}

	# Sofortbanking expects amount as xx.xx
	$args{amount} = sprintf( '%.2f', $args{amount} );

	$bop_object->content(
        %$provider_settings,
		amount      => $args{amount},
		card_number => $args{card_number},
		expiration  => $args{expiration},
		cvc         => $args{cvc},
        first_name  => $args{first_name},
        last_name   => $args{last_name},
		login       => $provider_settings->{login},
		password    => $provider_settings->{password},
		type        => $args{type} || $provider_settings->{type} || 'CC',
		action => $args{action} || $provider_settings->{action} || 'Authorization Only',
	);

	eval { $bop_object->submit(); };

	if ($@) {
		die "Payment with provider ", $self->{provider}, " failed: ", $@;
	}

	if ( $bop_object->is_success() ) {
        $self->_set_is_success(1);

		if ( $bop_object->can('popup_url') ) {
			debug( "Success!  Redirect browser to " . $bop_object->popup_url() );
		}
        else {
            debug("Successful payment, authorization: ",
                  $bop_object->authorization);
            debug("Order number: ", $bop_object->order_number);
            $self->_set_authorization($bop_object->authorization);
            $self->_set_order_number($bop_object->order_number);
        }
	}
	else {
		debug( 'Card was rejected by ', $self->provider, ': ' , $bop_object->error_message );
        $self->_set_error_message($bop_object->error_message);
        return;
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
