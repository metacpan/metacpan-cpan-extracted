package Business::PayPal::API::CaptureRequest;
$Business::PayPal::API::CaptureRequest::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;

#use SOAP::Lite +trace => 'debug';
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(DoCaptureRequest);

sub DoCaptureRequest {
    my $self = shift;
    my %args = @_;

    my %types = (
        AuthorizationID => 'xs:string',

        #The inclusion of the "ebl:CompleteCodeType" here, or any other reasonable type,
        #causes and error. Assigning a null string allows the module to work normally
        #with the exception that testing for "Success" fails, one must test for not
        #being a "Failure"... there may be a life lesson here.
        CompleteType => '',
        Amount       => 'ebl:BasicAmountType',
        Note         => 'xs:string',
    );

    $args{currencyID}   ||= 'USD';
    $args{CompleteType} ||= 'Complete';

    my @ref_trans = (
        $self->version_req,
        SOAP::Data->name( AuthorizationID => $args{AuthorizationID} )
            ->type( $types{AuthorizationID} ),
        SOAP::Data->name( CompleteType => $args{CompleteType} )
            ->type( $types{CompleteType} ),
    );

    if ( $args{Amount} ) {
        push @ref_trans,
            SOAP::Data->name( Amount => $args{Amount} )
            ->type( $types{Amount} )
            ->attr( { currencyID => $args{currencyID} } );
    }

    my $request
        = SOAP::Data->name(
        DoCaptureRequest => \SOAP::Data->value(@ref_trans) )
        ->type("ns:DoCaptureRequestType");

    my $som = $self->doCall( DoCaptureReq => $request )
        or return;

    my $path = '/Envelope/Body/DoCaptureResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }
    $path .= '/DoCaptureResponseDetails/PaymentInfo';
    $self->getFields(
        $som, $path,
        \%response,
        {
            TransactionID       => 'TransactionID',
            ParentTransactionID => 'ParentTransactionID',
            ReceiptID           => 'ReceiptID',
            TransactionType     => 'TransactionType',
            PaymentType         => 'PaymentType',
            PaymentDate         => 'PaymentDate',
            GrossAmount         => 'GrossAmount',
            FeeAmount           => 'FeeAmount',
            SettleAmount        => 'SettleAmount',
            TaxAmount           => 'TaxAmount',
            ExchangeRate        => 'ExchangeRate',
            PaymentStatus       => 'PaymentStatus',
            PendingReason       => 'PendingReason',
            ReasonCode          => 'ReasonCode',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::CaptureRequest - PayPal CaptureRequest API

=head1 VERSION

version 0.76

=head1 SYNOPSIS

  use Business::PayPal::API::CaptureRequest;

  ## see Business::PayPal::API documentation for parameters
  my $pp = new Business::PayPal::API::DoCaptureRequest ( ... );

  my %response = $pp->DoCaptureRequest( AuthorizationID => $transid,
                                        CompleteType    => 'Complete',
                                        Amount          => '13.00',
                                        Note            => "Give the fiddler his due." );

=head1 DESCRIPTION

B<Business::PayPal::API::DoCaptureRequest> implements PayPal's
B<CaptureRequest> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 CaptureRequest

Implements PayPal's B<CaptureRequest> API call. Supported
parameters include:

  AuthorizationID
  CompleteType (defaults to 'Complete' unless set to 'NotComplete')
  Amount
  currencyID (Currently must be the default, 'USD')
  Note ("String, < 255 char, indicating information about the charges.")

as described in the PayPal "Web Services API Reference" document. The
default B<currencyID> setting is 'USD' if not otherwise specified. The
default B<CompleteType> setting is 'Complete' if not otherwise specified.

Returns a hash containing the results of the transaction.

Example:

  my %resp = $pp->DoCaptureRequest (
                                     AuthorizationID => $auth_id,
                                     CompleteType    => 'NotComplete',
                                     Amount          => '15.00',
                                     CurrencyID     => 'USD',
                                    );

  if( $resp{Ack} eq 'Failure' ) {
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

# ABSTRACT: PayPal CaptureRequest API

