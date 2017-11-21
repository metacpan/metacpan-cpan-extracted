package Business::PayPal::API::GetTransactionDetails;
$Business::PayPal::API::GetTransactionDetails::VERSION = '0.77';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(GetTransactionDetails);    ## fake exporter

sub GetTransactionDetails {
    my $self = shift;
    my %args = @_;

    my @trans = (
        $self->version_req,
        SOAP::Data->name( TransactionID => $args{TransactionID} )
            ->type('xs:string'),
    );

    my $request
        = SOAP::Data->name(
        GetTransactionDetailsRequest => \SOAP::Data->value(@trans) )
        ->type("ns:GetTransactionDetailsRequestType");

    my $som = $self->doCall( GetTransactionDetailsReq => $request )
        or return;

    my $path = '/Envelope/Body/GetTransactionDetailsResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $path .= '/PaymentTransactionDetails';

    $self->getFields(
        $som, $path,
        \%response,
        {
            Business   => '/ReceiverInfo/Business',
            Receiver   => '/ReceiverInfo/Receiver',
            ReceiverID => '/ReceiverInfo/ReceiverID',

            Payer       => '/PayerInfo/Payer',
            PayerID     => '/PayerInfo/PayerID',
            PayerStatus => '/PayerInfo/PayerStatus',

            Salutation => '/PayerInfo/PayerName/Salutation',
            FirstName  => '/PayerInfo/PayerName/FirstName',
            MiddleName => '/PayerInfo/PayerName/MiddleName',
            LastName   => '/PayerInfo/PayerName/LastName',

            PayerCountry  => '/PayerInfo/PayerCountry',
            PayerBusiness => '/PayerInfo/PayerBusiness',

            AddressOwner    => '/PayerInfo/Address/AddressOwner',
            AddressStatus   => '/PayerInfo/Address/AddressStatus',
            ADD_Name        => '/PayerInfo/Address/Name',
            Street1         => '/PayerInfo/Address/Street1',
            Street2         => '/PayerInfo/Address/Street2',
            CityName        => '/PayerInfo/Address/CityName',
            StateOrProvince => '/PayerInfo/Address/StateOrProvince',
            Country         => '/PayerInfo/Address/Country',
            CountryName     => '/PayerInfo/Address/CountryName',
            Phone           => '/PayerInfo/Address/Phone',
            PostalCode      => '/PayerInfo/Address/PostalCode',

            TransactionID         => '/PaymentInfo/TransactionID',
            ParentTransactionID   => '/PaymentInfo/ParentTransactionID',
            ReceiptID             => '/PaymentInfo/ReceiptID',
            TransactionType       => '/PaymentInfo/TransactionType',
            PaymentType           => '/PaymentInfo/PaymentType',
            PaymentDate           => '/PaymentInfo/PaymentDate',
            GrossAmount           => '/PaymentInfo/GrossAmount',
            FeeAmount             => '/PaymentInfo/FeeAmount',
            SettleAmount          => '/PaymentInfo/SettleAmount',
            TaxAmount             => '/PaymentInfo/TaxAmount',
            ExchangeRate          => '/PaymentInfo/ExchangeRate',
            PaymentStatus         => '/PaymentInfo/PaymentStatus',
            PendingReason         => '/PaymentInfo/PendingReason',
            ReasonCode            => '/PaymentInfo/ReasonCode',
            ProtectionEligibility => '/PaymentInfo/ProtectionEligibility',

            InvoiceID => '/PaymentItemInfo/InvoiceID',
            Custom    => '/PaymentItemInfo/Custom',
            Memo      => '/PaymentItemInfo/Memo',
            SalesTax  => '/PaymentItemInfo/SalesTax',

            PII_SalesTax => '/PaymentItemInfo/PaymentItem/SalesTax',
            PII_Name     => '/PaymentItemInfo/PaymentItem/Name',
            PII_Number   => '/PaymentItemInfo/PaymentItem/Number',
            PII_Quantity => '/PaymentItemInfo/PaymentItem/Quantity',
            PII_Amount   => '/PaymentItemInfo/PaymentItem/Amount',
            PII_Options  => '/PaymentItemInfo/PaymentItem/Options',

            PII_SubscriptionID =>
                '/PaymentItemInfo/Subscription/SubscriptionID',
            PII_SubscriptionDate =>
                '/PaymentItemInfo/Subscription/SubscriptionDate',
            PII_EffectiveDate =>
                '/PaymentItemInfo/Subscription/EffectiveDate',
            PII_RetryTime   => '/PaymentItemInfo/Subscription/RetryTime',
            PII_Username    => '/PaymentItemInfo/Subscription/Username',
            PII_Password    => '/PaymentItemInfo/Subscription/Password',
            PII_Recurrences => '/PaymentItemInfo/Subscription/Recurrences',
            PII_reattempt   => '/PaymentItemInfo/Subscription/reattempt',
            PII_recurring   => '/PaymentItemInfo/Subscription/recurring',
            PII_Amount      => '/PaymentItemInfo/Subscription/Amount',
            PII_period      => '/PaymentItemInfo/Subscription/period',

            PII_BuyerID     => '/PaymentItemInfo/Auction/BuyerID',
            PII_ClosingDate => '/PaymentItemInfo/Auction/ClosingDate',
            PII_multiItem   => '/PaymentItemInfo/Auction/multiItem',
        }
    );

    ## multiple payment items
    my $paymentitems = $self->getFieldsList(
        $som,
        $path . '/PaymentItemInfo/PaymentItem',
        {
            SalesTax => 'SalesTax',
            Name     => 'Name',
            Number   => 'Number',
            Quantity => 'Quantity',
            Amount   => 'Amount',
        }
    );

    if ( scalar(@$paymentitems) > 0 ) {

        # Options data must be extracted differently.  Specifically, the
        # "interesting" parts of the Options data is not in the values inside
        # the $som structure (which means $som->valueof(), which
        # $self->getFieldsList() above calls underneath, won't extract the
        # useful data, because the values are empty.

        # The convoluted loop below finds any Options values and matches them
        # up properly with the correct PaymentItem.  Note that the loop is
        # written this way to account for the fact that there may be multiple
        # PaymentItems.

        # Finally, I contemplated placing this loop below in getFieldsList()
        # with a special-case for Options, but I am not sure it belongs
        # there.  Ultimately, I think this is unique to the
        # GetTransactionsDetails call in the API, and thus it's more
        # appropriately placed here.
        my $ii = 0;
        my @fulloptions;
        foreach
            my $rec ( $som->dataof( $path . '/PaymentItemInfo/PaymentItem' ) )
        {
            my %options;
            foreach my $subrec ( $rec->value() ) {
                foreach my $fieldrec ( $$subrec->value() ) {
                    $options{ $fieldrec->attr()->{name} }
                        = $fieldrec->attr()->{value}
                        if ( $fieldrec->name() eq "Options" );
                }
            }
            $paymentitems->[$ii]{Options} = \%options;
            push( @fulloptions, \%options );
        }

        # Now, we can save the payment items properly
        $response{PaymentItems} = $paymentitems;

        # And set the PII_Options properly too.
        $response{PII_Options} = \@fulloptions;
    }

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::GetTransactionDetails - PayPal GetTransactionDetails API

=head1 VERSION

version 0.77

=head1 SYNOPSIS

    use Business::PayPal::API::GetTransactionDetails;
    my $pp = Business::PayPal::API::GetTransactionDetails->new( ... );

or

    # see Business::PayPal::API documentation for parameters
    use Business::PayPal::API qw(GetTransactionDetails);
    my $pp = Business::PayPal::API->new( ... );

    my %response = $pp->GetTransactionDetails( TransactionID => $transid, );

=head1 DESCRIPTION

B<Business::PayPal::API::GetTransactionDetails> implements PayPal's
B<GetTransactionDetails> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 GetTransactionDetails

Implements PayPal's B<GetTransactionDetails> API call. Supported
parameters include:

  TransactionID

as described in the PayPal "Web Services API Reference" document.

Returns a hash containing the transaction details, including these fields:

  Business
  Receiver
  ReceiverID

  Payer
  PayerID
  PayerStatus

  Salutation
  FirstName
  MiddleName
  LastName

  PayerCountry
  PayerBusiness

  AddressOwner
  AddressStatus
  ADD_Name
  Street1
  Street2
  CityName
  StateOrProvince
  Country
  CountryName
  Phone
  PostalCode

  TransactionID
  ParentTransactionID
  ReceiptID
  TransactionType
  PaymentType
  PaymentDate
  GrossAmount
  FeeAmount
  SettleAmount
  TaxAmount
  ExchangeRate
  PaymentStatus
  PendingReason
  ReasonCode

  InvoiceID
  Custom
  Memo
  SalesTax

  PII_SaleTax
  PII_Name
  PII_Number
  PII_Quantity
  PII_Amount
  PII_Options

  PII_SubscriptionID
  PII_SubscriptionDate
  PII_EffectiveDate
  PII_RetryTime
  PII_Username
  PII_Password
  PII_Recurrences
  PII_reattempt
  PII_recurring
  PII_Amount
  PII_period

  PII_BuyerID
  PII_ClosingDate
  PII_multiItem

As described in the API document. Note: some fields have prefixes to
remove ambiguity for like-named fields (e.g., "PII_").

If there are multiple PaymentItems, then an additional field
'PaymentItems' will be available with an arrayref of PaymentItem
records:

  PaymentItems => [ { SalesTax => ...,
                      Name     => '...',
                      Number   => '...',
                      Quantity => '...',
                      Amount   => '...',
                      Options  => { 'key0' => 'value0',
                                    'key1' => 'value1' },
                    },
                    { SalesTax => ..., etc.
                    } ]

Example:

  my %resp = $pp->GetTransactionDetails( TransactionID => $trans_id );
  print "Payer: $resp{Payer}\n";

  for my $item ( @{ $resp{PaymentItems} } ) {
      print "Name: " . $item->{Name} . "\n";
      print "Amt: " . $item->{Amount} . "\n";
      for my $optionname (keys %$item->{Options}) {
          print "Option: $optionname is " . $item->{Options}{$optionname} . "\n";
      }
  }

=head2 PaymentItem Options Limitations

Note, BTW, that PayPal has a limitation such that each PaymentItem can
contain only two Options.  See:
   L<https://www.paypal.com/cgi-bin/webscr?cmd=p/xcl/rec/options-help-outside>
   L<https://developer.paypal.com/webapps/developer/docs/classic/paypal-payments-standard/integration-guide/Appx_websitestandard_htmlvariables/>

This hack may be of interest if you want to sneak in four options:
   L<https://ppmts.custhelp.com/app/answers/detail/a_id/298/kw/soap%20gettransactiondetails%20option>

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

# ABSTRACT: PayPal GetTransactionDetails API

