package Business::EDI::CodeList::ProductCharacteristicIdentificationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7139;}
my $usage       = 'I';

# 7139  Product characteristic identification code              [I]
# Desc: Code specifying the identification of a product
# characteristic.
# Repr: an..3

my %code_hash = (
'1' => [ 'TCV',
    'TCV tariff is applicable for the given travel service (TCV = Tarif Commun Voyageurs, ordinary tariff for travellers).' ],
'2' => [ 'Global tariff',
    'All inclusive tariff is applicable for the given travel service.' ],
'3' => [ 'East - West tariff',
    'Tariff used for traffic from east to west or vice versa.' ],
'4' => [ 'No published tariff',
    'There is no published tariff for the service.' ],
'5' => [ 'Train with TCV or Market Price',
    'Train running with service that can be sold at TCV (Tarif Commun Voyageurs - ordinary tariff for travellers) or Market Price.' ],
);
sub get_codes { return \%code_hash; }

1;
