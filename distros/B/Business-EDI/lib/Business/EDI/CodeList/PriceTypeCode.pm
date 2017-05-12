package Business::EDI::CodeList::PriceTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5375;}
my $usage       = 'C';

# 5375  Price type code                                         [C]
# Desc: Code specifying the type of price.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Cancellation price',
    'Price authorized to be charged in the event of an order being cancelled.' ],
'AB' => [ 'Per ton',
    'To indicate that the price applies per ton.' ],
'AC' => [ 'Minimum order price',
    'A code to identify the price when the minimum number is purchased.' ],
'AD' => [ 'Export price',
    'A code to identify a price for the export market.' ],
'AE' => [ 'Range dependent price',
    'A code identifying the price for a specific range of purchase quantities.' ],
'AI' => [ 'Active ingredient',
    'The price is referring to the active ingredient.' ],
'AQ' => [ 'As is quantity',
    'The price is referring to the measured quantity.' ],
'CA' => [ 'Catalogue',
    'Code specifying the catalogue price.' ],
'CT' => [ 'Contract',
    'Code specifying the contract price.' ],
'CU' => [ 'Consumer unit',
    'The price is referring to the consumer unit.' ],
'DI' => [ 'Distributor',
    'Code specifying the distributor price.' ],
'EC' => [ 'ECSC price',
    'Price registered at European Commission Steel and Carbon office (DG III).' ],
'NW' => [ 'Net weight',
    'Code specifying the net weight price.' ],
'PC' => [ 'Price catalogue',
    'Code specifying the catalogue price.' ],
'PE' => [ 'Per each',
    'Code specifying the price per item.' ],
'PK' => [ 'Per kilogram',
    'Code specifying the price per kilogram.' ],
'PL' => [ 'Per litre',
    'Code specifying the price per litre.' ],
'PT' => [ 'Per tonne',
    'Code specifying the price per tonne.' ],
'PU' => [ 'Specified unit',
    'Code specifying the price per specified unit.' ],
'PV' => [ 'Provisional price',
    'Code specifying a provisional price.' ],
'PW' => [ 'Gross weight',
    'Code specifying the gross weight price.' ],
'QT' => [ 'Quoted',
    'Code specifying the quoted price.' ],
'SR' => [ 'Suggested retail',
    'Code specifying the suggested retail price.' ],
'TB' => [ 'To be negotiated',
    'Code specifying that the price has to be negotiated.' ],
'TU' => [ 'Traded unit',
    'The price is referring to the traded unit.' ],
'TW' => [ 'Theoretical weight',
    'Weight calculated on ordered dimension (length, width, thickness) not on final dimension (e.g. steel products).' ],
'WH' => [ 'Wholesale',
    'Code specifying the wholesale price.' ],
'WI' => [ 'Gross volume',
    'The price is calculated based on gross volume.' ],
);
sub get_codes { return \%code_hash; }

1;
