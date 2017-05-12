package Business::EDI::CodeList::DutyOrTaxOrFeeCategoryCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5305;}
my $usage       = 'B';

# 5305  Duty or tax or fee category code                        [B]
# Desc: Code specifying a duty or tax or fee category.
# Repr: an..3

my %code_hash = (
'A' => [ 'Mixed tax rate',
    'Code specifying that the rate is based on mixed tax.' ],
'AA' => [ 'Lower rate',
    'Tax rate is lower than standard rate.' ],
'AB' => [ 'Exempt for resale',
    'A tax category code indicating the item is tax exempt when the item is bought for future resale.' ],
'AC' => [ 'Value Added Tax (VAT) not now due for payment',
    'A code to indicate that the Value Added Tax (VAT) amount which is due on the current invoice is to be paid on receipt of a separate VAT payment request.' ],
'AD' => [ 'Value Added Tax (VAT) due from a previous invoice',
    'A code to indicate that the Value Added Tax (VAT) amount of a previous invoice is to be paid.' ],
'AE' => [ 'VAT Reverse Charge',
    'Code specifying that the standard VAT rate is levied from the invoicee.' ],
'B' => [ 'Transferred (VAT)',
    'VAT not to be paid to the issuer of the invoice but directly to relevant tax authority.' ],
'C' => [ 'Duty paid by supplier',
    'Duty associated with shipment of goods is paid by the supplier; customer receives goods with duty paid.' ],
'E' => [ 'Exempt from tax',
    'Code specifying that taxes are not applicable.' ],
'G' => [ 'Free export item, tax not charged',
    'Code specifying that the item is free export and taxes are not charged.' ],
'H' => [ 'Higher rate',
    'Code specifying a higher rate of duty or tax or fee.' ],
'O' => [ 'Services outside scope of tax',
    'Code specifying that taxes are not applicable to the services.' ],
'S' => [ 'Standard rate',
    'Code specifying the standard rate.' ],
'Z' => [ 'Zero rated goods',
    'Code specifying that the goods are at a zero rate.' ],
);
sub get_codes { return \%code_hash; }

1;
