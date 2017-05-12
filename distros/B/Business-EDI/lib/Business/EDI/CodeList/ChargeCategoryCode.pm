package Business::EDI::CodeList::ChargeCategoryCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5237;}
my $usage       = 'B';

# 5237  Charge category code                                    [B]
# Desc: Code specifying the category of charges.
# Repr: an..3

my %code_hash = (
'1' => [ 'All charges',
    'All amounts calculated by the carrier in accordance with tariffs or in case of special events during the voyage (e.g. Rail - freights costs - additional costs).' ],
'2' => [ 'Additional charges',
    'Charges calculated by the carrier for specific events like re-weighting, re-loading, unexpected operations, services required during the voyage, etc.' ],
'3' => [ 'Transport charges + additional charges',
    'Transport charges plus Additional charges (e.g. for re- loading, re-weighting or unexpected operations) that must be precised in the payment conditions by the consignor (other charges must be taken in account by the consignee).' ],
'4' => [ 'Basic freight',
    'The basic freight payable on the cargo as per tariff.' ],
'5' => [ 'Destination haulage charges',
    'Haulage charges for transporting goods to the destination.' ],
'6' => [ 'Disbursement',
    "Sums paid out by ship's agent at a port and recovered from the carrier." ],
'7' => [ 'Destination port charges',
    'Charges payable at the port of destination.' ],
'8' => [ 'Miscellaneous charges',
    'Miscellaneous charges not otherwise categorized.' ],
'9' => [ 'Transport charges up to a specified location',
    'Transport charges to be paid by a specified party for a part of a voyage, i.e. up to a specified location.' ],
'10' => [ 'Origin port charges',
    'Charges payable at the port of origin.' ],
'11' => [ 'Origin haulage charges',
    'Haulage charges for the pickup of goods at origin.' ],
'12' => [ 'Other charges',
    'Unspecified charges.' ],
'13' => [ 'Specific amount payable',
    'Amount that the consignor agrees to be invoiced or to pay. This amount is part of the total charges applied to the consignment.' ],
'14' => [ 'Transport costs (carriage charges)',
    'Monetary amount calculated on the basis of the transport tariffs or contract eventually including charges or other costs.' ],
'15' => [ 'All costs up to a specified location',
    'All amounts to be paid by the consignor for a part of the voyage, i.e. up to a location that must be precised. (The remaining part of the voyage to be paid by the consignee) The amounts are calculated by the carrier in accordance with tariffs or in case of special events during the voyage (e.g. rail - freight costs - additional costs).' ],
'16' => [ 'Weight/valuation charge',
    'Code to indicate weight/valuation charges to be either wholly prepaid or wholly collect.' ],
'17' => [ 'All costs',
    'All cost elements.' ],
'19' => [ 'Supply of certificate of shipment',
    'Charges payable for the supply of a certificate of shipment.' ],
'20' => [ 'Supply of consular formalities or certificate of origin',
    'Charges payable for the supply of consular formalities or certificate of origin.' ],
'21' => [ 'Supply of non-categorised documentation in paper form',
    'Charges payable for the supply of one or more documents in paper form that are not otherwise categorised.' ],
'22' => [ 'Supply of customs formalities, export',
    'Charges payable for the supply of export customs formalities.' ],
'23' => [ 'Supply of customs formalities, transit',
    'Charges payable for the supply of transit customs formalities.' ],
'24' => [ 'Supply of customs formalities, import',
    'Charges payable for the supply of import customs formalities.' ],
);
sub get_codes { return \%code_hash; }

1;
