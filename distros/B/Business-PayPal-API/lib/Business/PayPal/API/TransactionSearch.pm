package Business::PayPal::API::TransactionSearch;
$Business::PayPal::API::TransactionSearch::VERSION = '0.77';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw( TransactionSearch );

sub TransactionSearch {
    my $self = shift;
    my %args = @_;

    my %types = (
        StartDate        => 'xs:dateTime',
        EndDate          => 'xs:dateTime',
        Payer            => 'ebl:EmailAddressType',
        Receiver         => 'ebl:EmailAddressType',
        ReceiptID        => 'xs:string',
        ProfileID        => 'xs:string',
        TransactionID    => 'xs:string',
        InvoiceID        => 'xs:string',
        PayerName        => 'xs:string',
        AuctionItemNumer => 'xs:string',
        TransactionClass => '',
        Amount           => 'ebl:BasicAmountType',
        CurrencyCode     => 'xs:token',
        Status           => '',
    );

    my @trans = (
        $self->version_req,
        SOAP::Data->name( StartDate => $args{StartDate} )
            ->type( delete $types{StartDate} )
    );

    for my $type ( keys %types ) {
        next unless $args{$type};
        push @trans,
            SOAP::Data->name( $type => $args{$type} )->type( $types{$type} );
    }

    my $request
        = SOAP::Data->name(
        TransactionSearchRequest => \SOAP::Data->value(@trans) )
        ->type("ns:TransactionSearchRequestType");

    my $som = $self->doCall( TransactionSearchReq => $request )
        or return;

    my $path = '/Envelope/Body/TransactionSearchResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    return $self->getFieldsList(
        $som,
        $path . '/PaymentTransactions',
        {
            Timestamp        => 'Timestamp',
            Timezone         => 'Timezone',
            Type             => 'Type',
            Payer            => 'Payer',
            PayerDisplayName => 'PayerDisplayName',
            TransactionID    => 'TransactionID',
            Status           => 'Status',
            GrossAmount      => 'GrossAmount',
            FeeAmount        => 'FeeAmount',
            NetAmount        => 'NetAmount',
        }
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::TransactionSearch - PayPal TransactionSearch API

=head1 VERSION

version 0.77

=head1 SYNOPSIS

    use Business::PayPal::API::TransactionSearch;

    # see Business::PayPal::API documentation for parameters
    my $pp = Business::PayPal::API::TransactionSearch->new( ... );

    my $transactions = $pp->TransactionSearch(
        StartDate     => '1998-01-01T00:00:00Z',
        TransactionID => $transid,
    );

    my $received = $pp->TransactionSearch(
        StartDate        => '2015-11-13T00:00:00Z',
        EndDate          => '2015-11-13T00:00:00Z',
        Status           => 'Success',
        TransactionClass => 'Received',
    );

=head1 DESCRIPTION

L<Business::PayPal::API::TransactionSearch> implements PayPal's
B<TransactionSearch> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 TransactionSearch

Implements PayPal's B<TransactionSearch> API call. Supported
parameters include:

  StartDate (required)
  EndDate
  Payer
  Receiver
  TransactionID
  PayerName
  AuctionItemNumber
  InvoiceID
  TransactionClass
  Amount
  CurrencyCode
  Status

as described in the PayPal "Web Services API Reference" document. The
syntax for StartDate is:

  YYYY-MM-DDTHH:MM:SSZ

'T' and 'Z' are literal characters 'T' and 'Z' respectively, e.g.:

  2005-12-22T08:51:28Z

Returns a list reference containing up to 100 matching records (as per
the PayPal Web Services API). Each record is a hash reference with the
following fields:

  Timestamp
  Timezone
  Type
  Payer
  PayerDisplayName
  TransactionID
  Status
  GrossAmount
  FeeAmount
  NetAmount

Example:

    my $records = $pp->TransactionSearch(
        StartDate => '2006-03-21T22:29:55Z',
        InvoiceID => '599294993',
    );

    for my $rec ( @$records ) {
        print "Record:\n";
        print "TransactionID: " . $rec->{TransactionID} . "\n";
        print "Payer Email: " . $rec->{Payer} . "\n";
        print "Amount: " . $rec->{GrossAmount} . "\n\n";
    }

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of L<Business::PayPal::API> for
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

# ABSTRACT: PayPal TransactionSearch API

