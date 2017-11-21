package Business::PayPal::API::AuthorizationRequest;
$Business::PayPal::API::AuthorizationRequest::VERSION = '0.77';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;

#use SOAP::Lite +trace => 'debug';
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(DoAuthorizationRequest);

sub DoAuthorizationRequest {
    my $self = shift;
    my %args = @_;

    my %types = (
        TransactionID => 'xs:string',
        Amount        => 'ebl:BasicAmountType',
    );

    $args{currencyID} ||= 'USD';

    my @ref_trans = (
        $self->version_req,
        SOAP::Data->name( TransactionID => $args{TransactionID} )
            ->type( $types{TransactionID} ),
    );

    push @ref_trans,
        SOAP::Data->name( Amount => $args{Amount} )->type( $types{Amount} )
        ->attr( { currencyID => $args{currencyID} } );

    my $request
        = SOAP::Data->name(
        DoAuthorizationRequest => \SOAP::Data->value(@ref_trans) )
        ->type("ns:AuthorizationRequestType");

    my $som = $self->doCall( DoAuthorizationReq => $request )
        or return;

    my $path = '/Envelope/Body/DoAuthorizationResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som, $path,
        \%response,
        {
            TransactionID => 'TransactionID',
            Amount        => 'Amount',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::AuthorizationRequest - PayPal AuthorizationRequest API

=head1 VERSION

version 0.77

=head1 SYNOPSIS

  use Business::PayPal::API::AuthorizationRequest;

  ## see Business::PayPal::API documentation for parameters
  my $pp = new Business::PayPal::API::DoAuthorizationRequest ( ... );

  my %response = $pp->DoAuthorizationRequest (
                                         TransactionID => $transid,
                                         CurrencyID    => $currencyID,
                                         Amount         => $amout,
                                         );

=head1 DESCRIPTION

B<Business::PayPal::API::AuthorizationRequest> implements PayPal's
B<AuthorizationRequest> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox. This request is only used with "Order" type
Authorizations. An "Order" must first be placed using the ExpressCheckout
module. DirectPayment authorizations can only be used for "Basic"
authorizations.

=head2 AuthorizationRequest

Implements PayPal's B<AuthorizationRequest> API call. Supported
parameters include:

  TransactionID
  Amount
  currencyID (defaults to 'USD' if not supplied)

as described in the PayPal "Web Services API Reference" document. The
default B<currencyID> setting is 'USD' if not otherwise specified.

Returns a hash containing the results of the transaction.

Example:

  my %resp = $pp->DoAuthorizationRequest (
                                          TransactionID => $trans_id,
                                          Amount        => '15.00',
                                          );

  unless( $resp{Ack} ne 'Success' ) {
      for my $error ( @{$response{Errors}} ) {
          warn "Error: " . $error->{LongMessage} . "\n";
      }
  }

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<https://developer.paypal.com/en_US/pdf/PP_APIReference.pdf>

=head1 AUTHORS

=over 4

=item *

Scott Wiersdorf <scott@perlcode.org>

=item *

Danny Hembree <danny@dynamical.org>

=item *

Bradley M. Kuhn <bkuhn@ebb.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006-2017 by Scott Wiersdorf, Danny Hembree, Bradley M. Kuhn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: PayPal AuthorizationRequest API

