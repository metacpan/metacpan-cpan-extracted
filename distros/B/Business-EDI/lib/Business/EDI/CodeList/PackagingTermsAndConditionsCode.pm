package Business::EDI::CodeList::PackagingTermsAndConditionsCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7073;}
my $usage       = 'B';

# 7073  Packaging terms and conditions code                     [B]
# Desc: Code specifying the packaging terms and conditions.
# Repr: an..3

my %code_hash = (
'1' => [ 'Packaging cost paid by supplier',
    'The cost of packaging is paid by the supplier.' ],
'2' => [ 'Packaging cost paid by recipient',
    'The cost of packaging is paid by the recipient.' ],
'3' => [ 'Packaging cost not charged (returnable)',
    'There is no charge for packaging because it is returnable.' ],
'4' => [ "Buyer's",
    'The packaging terms and conditions are specified by the buyer.' ],
'5' => [ "Carrier's durable",
    'Reusable packaging owned by the carrier.' ],
'6' => [ "Carrier's expendable",
    'Disposable packaging supplied by the carrier.' ],
'7' => [ "Seller's durable",
    'Reusable packaging owned by the seller.' ],
'8' => [ "Seller's expendable",
    'Disposable packaging supplied by the seller.' ],
'9' => [ "Special purpose buyer's durable",
    'Reusable packaging specifically designed for packaging of the referenced item and owned by the buyer.' ],
'10' => [ "Special purpose buyer's expendable",
    'Disposable packaging specifically designed for packaging of the referenced item.' ],
'11' => [ "Multiple usage buyer's durable",
    'Reusable multi-purpose packaging owned by the buyer.' ],
'12' => [ "Multiple usage seller's durable",
    'Reusable multi-purpose packaging owned by the seller.' ],
'13' => [ 'Not packed',
    'The referenced item is to be supplied without packaging.' ],
'14' => [ "Special purpose seller's durable",
    'Non-standard reusable packaging owned by the seller.' ],
'15' => [ 'Export quality',
    'The packaging used must meet durability and handling characteristics required for item export.' ],
'16' => [ 'Domestic quality',
    'The packaging used must meet durability and handling characteristics required for domestic usage.' ],
'17' => [ 'Packaging included in price',
    'The cost of packaging is included in the item price.' ],
'18' => [ 'Packaging costs split',
    'The cost of packaging is shared equally between the buyer and seller.' ],
'19' => [ 'Packaging costs invoiced separately',
    'The packaging cost will be invoiced on a separate message or document.' ],
'20' => [ 'Nil packaging costs',
    'The packaging is free of charge.' ],
'21' => [ 'Nil packaging costs if packaging returned',
    'The costs of packaging is reimbursed by the seller to buyer if packaging is returned.' ],
'22' => [ 'Return chargeable',
    'The return of packaging/empties is chargeable.' ],
'23' => [ 'Chargeable, two thirds of paid amount with credit note on',
    'return of loaned package The buyer receives two thirds of paid amount with credit note if loaned package is returned.' ],
'24' => [ 'Rented',
    'The package has been, or will be, rented.' ],
'25' => [ 'Safe return deposit',
    'A deposit paid to guarantee the safe return of the package.' ],
'26' => [ 'Not reusable',
    'The package is not reusable.' ],
'27' => [ 'Package exchangeable at the point of delivery',
    'The package may be exchanged at the point of delivery.' ],
'28' => [ 'Tamper evident package',
    'The package should give easy or immediate recognition that the package has been tampered with after it has been sealed.' ],
'29' => [ 'Labeled',
    'The package is labeled.' ],
'30' => [ 'Package not marked returnable',
    'The package is not marked returnable.' ],
);
sub get_codes { return \%code_hash; }

1;
