package Business::EDI::CodeList::TransportChargesPaymentMethodCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4215;}
my $usage       = 'B';

# 4215  Transport charges payment method code                   [B]
# Desc: Code specifying the payment method for transport
# charges.
# Repr: an..3

my %code_hash = (
'A' => [ 'Account',
    'The charges are to be charged to an account.' ],
'AA' => [ 'Cash on delivery service charge paid by consignor',
    'An indication that the consignor is responsible for the payment of the cash on delivery service charge.' ],
'AB' => [ 'Cash on delivery service charge paid by consignee',
    'An indication that the consignee is responsible for the payment of the cash on delivery service charge.' ],
'AC' => [ 'Insurance costs paid by consignor',
    'An indication that the consignor is responsible for the payment of the insurance costs.' ],
'AD' => [ 'Insurance costs paid by consignee',
    'An indication that the consignee is responsible for the payment of the insurance costs.' ],
'CA' => [ 'Advance collect',
    'The amount of freight or other charge on a shipment advanced by one transportation line to another or to the shipper, to be collected from consignee.' ],
'CC' => [ 'Collect',
    'A shipment on which freight charges will be paid by consignee.' ],
'CF' => [ 'Collect, freight credited to payment customer',
    'The freight is collect but has been paid by the shipper and will be credited to that party.' ],
'DF' => [ 'Defined by buyer and seller',
    'The payment method for transport charges have been defined by the buyer and seller.' ],
'FO' => [ 'FOB port of call',
    'Title and control of goods pass to the buyer at port of call. Responsibility for export taxes and cost of documents for overseas shipments have not been specified.' ],
'IC' => [ 'Information copy, no payment due',
    'Transaction set has been provided for information only.' ],
'MX' => [ 'Mixed',
    'The consignment is partially collect and partially prepaid.' ],
'NC' => [ 'Service freight, no charge',
    'The consignment is shipped on a service basis and there is no freight charge.' ],
'NS' => [ 'Not specified',
    'The payment method for transport charges have not been specified.' ],
'PA' => [ 'Advance prepaid',
    'Costs have been paid in advance.' ],
'PB' => [ 'Customer pick-up/backhaul',
    "Buyer's private carriage picks up the goods as a return load to the buyer's facility." ],
'PC' => [ 'Prepaid but charged to customer',
    'shipping charges have been paid in advance of shipment but are charged back to consignee usually as line item on invoice for the purchased goods.' ],
'PE' => [ 'Payable elsewhere',
    'Place of payment not known at the begin of conveyance.' ],
'PO' => [ 'Prepaid only',
    'Payment in advance of freight and/or other charges prior to delivery of shipment at destination, usually by shipper at point of origin.' ],
'PP' => [ 'Prepaid (by seller)',
    'Seller of goods makes payment to carrier for freight charges prior to shipment.' ],
'PU' => [ 'Pickup',
    'Customer is responsible for payment of pickup charges at shipping point.' ],
'RC' => [ 'Return container freight paid by customer',
    'The freight for returning the container is paid by the customer.' ],
'RF' => [ 'Return container freight free',
    'There is no freight charge for returning the container.' ],
'RS' => [ 'Return container freight paid by supplier',
    'The freight charge for returning the container is paid by the supplier.' ],
'TP' => [ 'Third party pay',
    'A third party, someone other than buyer or seller, is identified as responsible for payment of shipping charges.' ],
'WC' => [ 'Weight condition',
    'The payment method for transport charges are due to the weight.' ],
'WD' => [ 'Paid by supplier',
    'Transport charges will be paid by the supplier.' ],
'WE' => [ 'Paid by buyer',
    'Transport charges will be paid by the buyer.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
