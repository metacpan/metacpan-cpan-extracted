package Business::Giropay;

=head1 NAME

Business::Giropay - Giropay payments API

=head1 VERSION

Version 0.103

=cut

our $VERSION = '0.103';

use Business::Giropay::Request::Bankstatus;
use Business::Giropay::Request::Issuer;
use Business::Giropay::Request::Status;
use Business::Giropay::Request::Transaction;
use Business::Giropay::Notification;

use Moo;
with 'Business::Giropay::Role::Core', 'Business::Giropay::Role::Network',
  'Business::Giropay::Role::Urls';
use namespace::clean;

sub bankstatus {
    my ( $self, @args ) = @_;
    my $request = Business::Giropay::Request::Bankstatus->new(
        network    => $self->network,
        merchantId => $self->merchantId,
        projectId  => $self->projectId,
        sandbox    => $self->sandbox,
        secret     => $self->secret,
        @args,
    );
    return $request->submit;
}

sub issuer {
    my $self    = shift;
    my $request = Business::Giropay::Request::Issuer->new(
        network    => $self->network,
        merchantId => $self->merchantId,
        projectId  => $self->projectId,
        sandbox    => $self->sandbox,
        secret     => $self->secret,
    );
    return $request->submit;
}

sub status {
    my ( $self, @args ) = @_;
    my $request = Business::Giropay::Request::Status->new(
        network    => $self->network,
        merchantId => $self->merchantId,
        projectId  => $self->projectId,
        secret     => $self->secret,
        @args,
    );
    return $request->submit;
}

sub transaction {
    my ( $self, @args ) = @_;
    my $request = Business::Giropay::Request::Transaction->new(
        network     => $self->network,
        merchantId  => $self->merchantId,
        projectId   => $self->projectId,
        sandbox     => $self->sandbox,
        secret      => $self->secret,
        urlRedirect => $self->urlRedirect,
        urlNotify   => $self->urlNotify,
        @args,
    );
    return $request->submit;
}

sub notification {
    my ( $self, @args ) = @_;
    return Business::Giropay::Notification->new(
        merchantId => $self->merchantId,
        projectId  => $self->projectId,
        secret     => $self->secret,
        @args,
    );
}

=head1 DESCRIPTION

B<Business::Giropay> implement's Giropay's GiroCheckout API to make direct
calls to Giropay's payments server.

Giropay facilitates payments via various provider networks in addition to 
their own. This module currently supports the following networks:

=over

=item eps - EPS (Austria)

=item giropay - Giropay's own network (Germany)

=item ideal - iDEAL (The Netherlands)

=back

Contributions to allow this module to support other networks available via
Giropay are most welcome.

=head1 SYNOPSIS

    use Business::Giropay;

    my $giropay = Business::Giropay->new(
        network    => 'giropay',
        merchantId => '123456789',
        projectId  => '1234567',
        sandbox    => 1,
        secret     => 'project_secret',
    );

    my $response = $giropay->transaction(
        merchantTxId => 'tx-10928374',
        amount       => 2938,               # 29.38 in cents
        currency     => 'EUR',
        purpose      => 'Test Transaction',
        bic          => 'TESTDETT421',
        urlRedirect  => 'https://www.example.com/return_page',
        urlNotify    => 'https://www.example.com/api/giropay/notify',
    );

    if ( $response->success ) {
        # all is good so redirect customer to GiroCheckout
    }
    else {
        # transaction request failed
    }

C<urlRedirect> and C<urlNotify> can also be passed to C<new>:

    use Business::Giropay;

    my $giropay = Business::Giropay->new(
        network     => 'giropay',
        merchantId  => '123456789',
        projectId   => '1234567',
        urlRedirect => 'https://www.example.com/return_page',
        urlNotify   => 'https://www.example.com/api/giropay/notify',
        sandbox     => 1,
        secret      => 'project_secret',
    );

    my $response = $giropay->transaction(
        merchantTxId => 'tx-10928374',
        amount       => 2938,               # 29.38 in cents
        currency     => 'EUR',
        purpose      => 'Test Transaction',
        bic          => 'TESTDETT421',
    );

    if ( $response->success ) {
        # all is good so redirect customer to GiroCheckout
    }
    else {
        # transaction request failed
    }


Elsewhere in your C<urlNotify> route:

    my $notification = $giropay->notification( %request_params );

    if ( $notification->success ) {
        # save stuff in DB - customer probably still on bank site
    }
    else {
        # bad stuff happened - make a note of it
    }

And in the C<urlRedirect> route:

    my $notification = $giropay->notification( %request_params );

    if ( $notification->success ) {
        # we should already have earlier notification but check anyway
        # in case customer came back before we received it then thank
        # customer for purchase
    }
    else {
        # bad stuff - check out the details and tell the customer
    }


=head1 ATTRIBUTES

See L<Business::Giropay::Role::Core/ATTRIBUTES> for full details of the
following attributes that can be passed to C<new>.

=over

=item * network

=item * merchantId

=item * projectId

=item * sandbox

=item * secret

=back

See L<Business::Giropay::Role::Urls/ATTRIBUTES> for full details of the
following attributes that can be passed to C<new>.

=over

=item * urlRedirect

=item * urlNotify

=back

=head1 METHODS

B<NOTE:> it is not necessary to pass in any attributes that were already
passed to C<new> since they are passed through automatically.

=head2 bankstatus %attributes

This API call checks if a bank supports the giropay/eps payment method.

Returns a L<Business::Giropay::Response::Bankstatus> object.

See L<Business::Giropay::Request::Bankstatus/ATTRIBUTES> for full details of
the following attribute that can be passed to this method:

=over

=item * bic

=back

=head2 issuer

Returns a L<Business::Giropay::Response::Issuer> object which includes a
list which contains all supported giropay/eps/ideal issuer banks.

=head2 transaction %attributes

This API call creates the start of a transaction and returns a
L<Business::Giropay::Response::Transaction> object. If the response indicates
success then customer can be redirected to
L<Business::Giropay::Response::Transaction/redirect> to complete payment.

Returns a L<Business::Giropay::Response::Transaction> object.

See L<Business::Giropay::Request::Transaction/ATTRIBUTES> for full details of
the following attributes that can be passed to this method:

=over

=item * merchantTxId

=item * amount

=item * currency

=item * purpose

=item * bic

=item * urlRedirect

=item * urlNotify

=back

=head2 notification %query_params

Accepts query parameters and returns a L<Business::Giropay::Notification>
object.

=head2 status %attributes

Returns a L<Business::Giropay::Response::Status> object with details of
the requested transaction.

See L<Business::Giropay::Request::Status/ATTRIBUTES> for full details of
the following attribute that can be passed to this method:

=over

=item * reference

=back

=head1 SEE ALSO

L<GiroCheckout API|http://api.girocheckout.de/en:start> which has links for
the various payment network types (giropay, eps, etc). For L</status> see
L<http://api.girocheckout.de/en:tools:transaction_status>.

=head1 TODO

Add more of Giropay's payment networks.

=head1 AUTHOR

  Peter Mottram (SysPete) <peter@sysnix.com>

=head1 CONTRIBUTORS

  Alexandr Ciornii (chorny)

=head1 ACKNOWLEDGEMENTS

Many thanks to L<CALEVO Equestrian|https://www.calevo.com/> for sponsoring
development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Mottram (SysPete) <peter@sysnix.com>

This program is free software; you can redistribute it and/or modify it
under the terms of Perl itself.

=cut

1;
