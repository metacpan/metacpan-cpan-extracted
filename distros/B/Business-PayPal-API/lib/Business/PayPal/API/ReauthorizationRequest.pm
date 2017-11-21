package Business::PayPal::API::ReauthorizationRequest;
$Business::PayPal::API::ReauthorizationRequest::VERSION = '0.77';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(DoReauthorizationRequest);

sub DoReauthorizationRequest {
    my $self = shift;
    my %args = @_;

    my %types = (
        AuthorizationID => 'xs:string',
        Amount          => 'ebl:BasicAmountType',
    );

    $args{currencyID} ||= 'USD';

    my @ref_trans = (
        $self->version_req,
        SOAP::Data->name( AuthorizationID => $args{AuthorizationID} )
            ->type( $types{AuthorizationID} ),
    );

    push @ref_trans,
        SOAP::Data->name( Amount => $args{Amount} )->type( $types{Amount} )
        ->attr( { currencyID => $args{currencyID} } );

    my $request
        = SOAP::Data->name(
        DoReauthorizationRequest => \SOAP::Data->value(@ref_trans) )
        ->type("ns:ReauthorizationRequestType");

    my $som = $self->doCall( DoReauthorizationReq => $request )
        or return;

    my $path = '/Envelope/Body/DoReauthorizationResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som, $path,
        \%response,
        {
            AuthorizationID => 'AuthorizationID',
            Amount          => 'Amount',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::ReauthorizationRequest - PayPal ReauthorizationRequest API

=head1 VERSION

version 0.77

=head1 SYNOPSIS

    use Business::PayPal::API::ReauthorizationRequest;

    ## see Business::PayPal::API documentation for parameters
    my $pp = Business::PayPal::API::ReauthorizationRequest->new( ... );

    my %response = $pp->DoReauthorizationRequest(
        AuthorizationID => $transid,
        Amount          => $amount,
        CurrencyID      => $currencyID
    );

=head1 DESCRIPTION

B<Business::PayPal::API::ReauthorizationRequest> implements PayPal's
B<DoReauthorizationRequest> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 DoReauthorizationRequest

Implements PayPal's B<DoReauthorizationRequest> API call. Supported
parameters include:

  AuthorizationID
  Amount
  currencyID (defaults to 'USD' if not supplied)

as described in the PayPal "Web Services API Reference" document. The
default B<currencyID> setting is 'USD' if not otherwise specified. The
DoReauthorization is not allowed before the three day grace period set
for the original AuthorizeRequest.

Returns a hash containing the results of the transaction.

Example:

  my %resp = $pp->DoReauthorizationRequest (
                                     AuthorizationID => $trans_id,
                                     Amount          => '15.00',
                                     CurrencyID      => 'USD'
                                      );

  unless( $resp{Ack} !~ /Success/ ) {
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

# ABSTRACT: PayPal ReauthorizationRequest API

