package Business::EDI::CodeList::CurrencyTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6343;}
my $usage       = 'C';

# 6343  Currency type code qualifier                            [C]
# Desc: Code qualifying the type of currency.
# Repr: an..3

my %code_hash = (
'1' => [ 'Customs valuation currency',
    'The currency of the monetary unit involved in the transaction for customs valuation.' ],
'2' => [ 'Insurance currency',
    'The currency of the monetary unit involved in the transaction for insurance purposes.' ],
'3' => [ 'Home currency',
    'The currency of the local monetary unit.' ],
'4' => [ 'Invoicing currency',
    'The currency of the monetary unit used for calculation in an invoice.' ],
'5' => [ 'Account currency',
    'The currency of the monetary unit of an account.' ],
'6' => [ 'Reference currency',
    'The currency of the monetary unit to be converted from.' ],
'7' => [ 'Target currency',
    'The currency of the monetary unit to be converted into.' ],
'8' => [ 'Price list currency',
    'The currency of the monetary unit used in a price list.' ],
'9' => [ 'Order currency',
    'The currency of the monetary unit used in an order.' ],
'10' => [ 'Pricing currency',
    'The currency of the monetary unit used for pricing purposes.' ],
'11' => [ 'Payment currency',
    'The currency of the monetary unit used for payment.' ],
'12' => [ 'Quotation currency',
    'The currency of the monetary unit used in a quotation.' ],
'13' => [ 'Recipient local currency',
    "The currency of the local monetary unit at recipient's location." ],
'14' => [ 'Supplier currency',
    'The currency of the monetary unit normally used by the supplier.' ],
'15' => [ 'Sender local currency',
    "The currency of the local monetary unit at sender's location." ],
'16' => [ 'Tariff currency',
    'The currency as per tariff.' ],
'17' => [ 'Charge calculation currency',
    'The currency in which the charges are calculated.' ],
'18' => [ 'Tax currency',
    'The currency in which tax amounts are due or have been paid.' ],
);
sub get_codes { return \%code_hash; }

1;
