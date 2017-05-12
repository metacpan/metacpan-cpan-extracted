package Business::EDI::CodeList::ExchangeRateCurrencyMarketIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6341;}
my $usage       = 'C';

# 6341  Exchange rate currency market identifier                [C]
# Desc: To identify an exchange rate currency market.
# Repr: an..3

my %code_hash = (
'AAA' => [ 'Paris exchange',
    'The currency exchange rate is set by the Paris exchange.' ],
'AAB' => [ 'Colombian official exchange (Central Bank of Colombia)',
    'The currency exchange rate is set by the Central Bank of Colombia.' ],
'AMS' => [ 'Amsterdam exchange',
    'The currency exchange rate is set by the Amsterdam exchange.' ],
'ARG' => [ 'Bolsa de Comercio de Buenos Aires',
    'Argentina exchange.' ],
'AST' => [ 'Australian exchange',
    'The currency exchange rate is set by the Australian exchange.' ],
'AUS' => [ 'Wien exchange',
    'Wiener Boersenkammer.' ],
'BEL' => [ 'Brussels exchange',
    'Commission de la Bourse Bruxelles.' ],
'CAN' => [ 'Toronto exchange',
    'The currency exchange rate is set by the Toronto exchange.' ],
'CAR' => [ 'Contractual agreement exchange rate',
    'The currency exchange rate is set by a written or spoken agreement between two or more parties.' ],
'CIE' => [ 'US Customs Information Exchange',
    'Currency rates published by the US Customs Information Exchange, 6 WTC, New York NY 10048-0945, USA.' ],
'DEN' => [ 'Copenhagen exchange',
    'Koebenhavns Fondsboers.' ],
'ECR' => [ 'European Community period exchange rate',
    'The currency exchange rate is set for a length of time by the European Community.' ],
'FIN' => [ 'Helsinki exchange',
    'The currency exchange rate is set by the Helsinki exchange.' ],
'FRA' => [ 'Frankfurt exchange',
    'The currency exchange rate is set by the Frankfurt exchange.' ],
'IMF' => [ 'International Monetary Fund',
    'The currency exchange rate is set by the International Monetary Fund.' ],
'LNF' => [ 'London exchange, first closing',
    'The currency exchange rate is set by the London exchange at the first closing.' ],
'LNS' => [ 'London exchange, second closing',
    'The currency exchange rate is set by the London exchange at the second closing.' ],
'MIL' => [ 'Milan exchange',
    'The currency exchange rate is set by the Milan exchange.' ],
'NOR' => [ 'Oslo exchange',
    'The currency exchange rate is set by the Oslo exchange.' ],
'NYC' => [ 'New York exchange',
    'The currency exchange rate is set by the New York exchange.' ],
'PHI' => [ 'Philadelphia exchange',
    'The currency exchange rate is set by the Philadelphia exchange.' ],
'SRE' => [ 'Specific railway exchange currency',
    'Specific rate of exchange applied to currency exchanges between rail companies and partners.' ],
'SWE' => [ 'Stockholm exchange',
    'The currency exchange rate is set by the Stockholm exchange.' ],
'ZUR' => [ 'Zurich exchange',
    'The currency exchange rate is set by the Zurich exchange.' ],
);
sub get_codes { return \%code_hash; }

1;
