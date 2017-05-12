package Business::EDI::CodeList::PriceCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5125;}
my $usage       = 'C';

# 5125  Price code qualifier                                    [C]
# Desc: Code qualifying a price.
# Repr: an..3

my %code_hash = (
'AAA' => [ 'Calculation net',
    'The price stated is the net price including allowances/ charges. Allowances/charges may be stated for information only.' ],
'AAB' => [ 'Calculation gross',
    'The price stated is the gross price to which allowances/ charges must be applied.' ],
'AAC' => [ 'Allowances and charges not included, tax included',
    'The price does not include the allowances and charges, but includes the taxes.' ],
'AAD' => [ 'Average selling price',
    'Average selling price of a product.' ],
'AAE' => [ 'Information price, excluding allowances or charges,',
    'including taxes The price stated is for information purposes only and excludes all allowances and charges. Taxes however are included in the price.' ],
'AAF' => [ 'Information price, excluding allowances or charges, and',
    'taxes The price stated is for information purposes only and excludes all allowances, charges and taxes.' ],
'AAG' => [ 'Additive unit price component',
    'A code to indicate that the price described is an additive component of the total price.' ],
'CAL' => [ 'Calculation price',
    'The price stated is the price for the calculation of the line item amount.' ],
'INF' => [ 'Information',
    'The price is provided for information.' ],
'INV' => [ 'Invoice price',
    'Referenced price taken from an invoice.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
