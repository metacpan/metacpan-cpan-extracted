package Business::OnlinePayment::PPIPayMover;

use strict;
use vars qw($VERSION @ISA $DEBUG);
use Carp;
use Business::OnlinePayment::PPIPayMover::constants;
use Business::OnlinePayment::PPIPayMover::TransactionClient;
use Business::OnlinePayment::PPIPayMover::CreditCardRequest;
use Business::OnlinePayment::PPIPayMover::CountryCodes;
use Business::OnlinePayment::PPIPayMover::CreditCardResponse;

$VERSION = '0.01';
@ISA = qw(Business::OnlinePayment);
$DEBUG = 0;

my $tranclient = new Business::OnlinePayment::PPIPayMover::TransactionClient;
#my $ccreq = new Business::OnlinePayment::PPIPayMover::CreditCardRequest;

sub set_defaults {
  my $self = shift;

    #$self->server('secure.linkpt.net');
    #$self->port('1129');

    $self->build_subs(qw(order_number avs_code));

}

sub map_fields {
  my $self = shift;

  my %content = $self->content();

  # ACTION MAP
  #    target types: SALE, ADJUSTMENT, AUTH, CAPTURE, CREDIT, FORCE_AUTH,
  #                  FORCE_SALE, QUERY_CREDIT, QUERY_PAYMENT or VOID
  my %actions = (
    'normal authorization' => 'SALE',
    'authorization only'   => 'AUTH',
    'credit'               => 'CREDIT',
    'post authorization'   => 'CAPTURE',
    'void'                 => 'VOID',
  );
  $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

  # TYPE MAP
  my %types = (
    'visa'              => 'CC',
    'mastercard'        => 'CC',
    'american express'  => 'CC',
    'discover'          => 'CC',
    'cc'                => 'CC',
    #'check'
  );
  $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
  $self->transaction_type($content{'type'});

  # stuff it back into %content
  $self->content(%content);
}

sub submit {
  my $self = shift;

    #type          =>
    #login         =>
    #password      =>
    #authorization =>

		    #name

    #order_number

		    #currency          =>

		    #check_type        =>
		    #account_name      =>
		    #account_number    => 
		    #account_type      =>
 		   #bank_name         => 
 		   #routing_code      =>
		    #customer_org      =>
  		  #customer_ssn      =>
  		  #license_num       =>
		    #license_state     =>
  		  #license_dob       =>
 		   #get from new() args instead# payee             =>
   		 #check_number      =>

		    #recurring_billing => 'cnp_recurring',

  $self->map_fields();

  my %content = $self->content;

  my($month, $year);
  unless ( $content{action} eq 'CAPTURE'
           || ( $content{'action'} =~ /^(CREDIT|VOID)$/
                && exists $content{'order_number'} )
         ) {

    if (  $self->transaction_type() =~
            /^(cc|visa|mastercard|american express|discover)$/i
       ) {
    } else {
        Carp::croak("PPIPayMover can't handle transaction type: ".
                    $self->transaction_type());
    }

    $content{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
      or croak "unparsable expiration $content{expiration}";

    ( $month, $year ) = ( $1, "20$2" );
    $month = '0'. $month if $month =~ /^\d$/;
  }

  my $ccreq = new Business::OnlinePayment::PPIPayMover::CreditCardRequest;

  $self->revmap_fields( $ccreq,

    'ChargeTotal'                  => 'amount',
    'ChargeType'                   => 'action',
    'CreditCardNumber'             => 'card_number',
    'CreditCardVerificationNumber' => 'cvv2',
    'ExpireMonth'                  => \$month,
    'ExpireYear'                   => \$year,

    'BillAddressOne'               => 'address',
    #'BillAddressTwo'               => '',
    'BillCity'                     => 'city',
    'BillCompany'                  => 'company',
    'BillCountryCode'              => 'country',
    #'BillCustomerTitle'            => '',
    'BillEmail',                   => 'email',
    'BillFax'                      => 'fax',
    'BillFirstName'                => 'first_name',
    'BillLastName'                 => 'last_name',
    #'BillMiddleName'               => '',
    'BillNote'                      => '',
    'BillPhone'                    => 'phone',
    'BillPostalCode'               => 'zip',
    'BillStateOrProvince'          => 'state',

    'ShipAddressOne'               => 'ship_address',
    #'ShipAddressTwo'               => '',
    'ShipCity'                     => 'ship_city',
    'ShipCompany'                  => 'ship_company',
    'ShipCountryCode'              => 'ship_country',
    #'ShipCustomerTitle'            => '',
    'ShipEmail',                   => 'ship_email',
    'ShipFax'                      => 'ship_fax',
    'ShipFirstName'                => 'ship_first_name',
    'ShipLastName'                 => 'ship_last_name',
    #'ShipMiddleName'               => '',
    'ShipNote'                      => '',
    'ShipPhone'                    => 'ship_phone',
    'ShipPostalCode'               => 'ship_zip',
    'ShipStateOrProvince'          => 'ship_state',

    #'OrderId'                      => 'order_number',
    'OrderId'                      => (int (rand 999999998) + 1 ), # XXX This can result in duplicate order ids.  You should use your own sequence instead.
    'BuyerCode'                    => '83487235',
    'CustomerIPAddress'            => 'customer_ip',
    'OrderCustomerId'              => 'customer_id',
    'OrderDescription'             => 'description',
    #'OrderUserId'                  => '',
    #'PurchaseOrderNumber'          => '',
    'TransactionConditionCode'     => \( TCC_CARDHOLDER_NOT_PRESENT_SECURE_ECOMMERCE ),
    #'ShippingCharge'               => '',
    #'StateTax'                     => '',
    #'TaxAmount'                    => '',
    #'TaxExempt'                    => '',

    'InvoiceNumber'                => 'invoice_number',
    'Industry'                     => \( RETAIL ),
    #'FolioNumber'                  => '',

    #'ChargeTotalIncludesRestaurant'
    #'ChargeTotalIncludesGiftshop'
    #'ChargeTotalIncludesMinibar'
    #'ChargeTotalIncludesPhone'
    #'ChargeTotalIncludesLaundry'
    #'ChargeTotalIncludesOther'

    #'ServiceRate'

    #'ServiceStartDay'
    #'ServiceStartMonth'
    #'ServiceStartYear'
    #'ServiceEndMonth'
    #'ServiceEndYear'
    #'ServiceEndDay'

    #'ServiceNoShow'

    #'ReferenceId'    => '', # XXX Use reference ID for follow-on transactions (CAPTURE, VOID)
    #'CAVV'
    #'XID'
    #'Track1'
    #'Track2'


  );

  # Send the transaction! (test token)

  my $token = $content{'login'};
  $token = "TEST$token" if $self->test_transaction();
  
  my $ccresponse = $tranclient->doTransaction( 
    "",     # transaction key (?)
    $ccreq, #cc request
    $token, #token
  );

  die $tranclient->GetErrorString unless defined $ccresponse;

  $self->result_code($ccresponse->GetResponseCode);
  $self->avs_code($ccresponse->GetAVSCode);
  $self->order_number($ccresponse->GetOrderId);

  if ( $self->result_code == 1 ) { # eq '1' ?
    $self->is_success(1);
    #$self->authorization($ccresponse->GetBankApprovalCode);
    $self->authorization($ccresponse->GetReferenceId); #"Identifier for follow-on transactions"
  } else {
    $self->is_success(0);
    $self->error_message($ccresponse->GetResponseCodeText);
  }

}

##  print "ResponseCode            : ", $ccresponse->GetResponseCode, "\n";
##  print "ResponseCodeText        : ", $ccresponse->GetResponseCodeText, "\n";
#  print "Timestamp               : ", $datetime, "\n";
#  print "IsoCode                 : ", $ccresponse->GetIsoCode, "\n";
##  print "OrderId                 : ", $ccresponse->GetOrderId, "\n";
##  print "BankApprovalCode        : ", $ccresponse->GetBankApprovalCode, "\n";
#  print "State                   : ", $ccresponse->GetState, "\n";
#  print "AuthorizedAmount        : ", $ccresponse->GetAuthorizedAmount, "\n";
#  print "OriginalAuthorizedAmount: ", $ccresponse->GetOriginalAuthorizedAmount,
#"\n";
#  print "CapturedAmount          : ", $ccresponse->GetCapturedAmount, "\n";
#  print "CreditedAmount          : ", $ccresponse->GetCreditedAmount, "\n";
#  print "TimeStampCreated        : ", $ccresponse->GetTimeStampCreated, "\n";
##  print "ReferenceId             : ", $ccresponse->GetReferenceId, "\n";
#  print "BankTransactionId       : ", $ccresponse->GetBankTransactionId, "\n";
#  print "BatchId                 : ", $ccresponse->GetBatchId, "\n";
#  #print "AVS Code                : ", $ccresponse->GetAVSCode, "\n";

#this is different from a "normal" B:OP revmap, it sets things in $ccreq
sub revmap_fields {
    my($self, $ccreq, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
      my $method = "Set$_";
      my $content = ref($map{$_}) ? ${ $map{$_} } : $content{$map{$_}};
      $ccreq->$method($content);
    }
}


1;
__END__

=head1 NAME

Business::OnlinePayment::PPIPayMover - PPI PayMover backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment( 'PPIPayMover' );

  $tx->content(
      login          => '195325FCC230184964CAB3A8D93EEB31888C42C714E39CBBB2E541884485D04B', #token
      type           => 'VISA',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      name           => 'Grub Tetris',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      email          => 'ivan-ppipaymover@420.am',
      card_number    => '4007000000027',
      expiration     => '09/12',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, JCB, Discover/Novus, Carte blanche/Di
ners Club

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 BUGS

=head1 AUTHOR

Ivan Kohler <ivan-ppipaymover@420.am>

=head1 COPYRIGHT AND LICENSE

Based on API components from PPI PayMover provided without clear licensing, so,
probably not freely licensable at the moment... assuming that can be resolved:

Business::OnlinePayment conversion copyright (c) 2006 Ivan Kohler
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Business::OnlinePayment>.

=cut
