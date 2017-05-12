package Business::EDI::CodeList::TradeClassCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4043;}
my $usage       = 'B';

# 4043  Trade class code                                        [B]
# Desc: Code identifying the class of trade.
# Repr: an..3

my %code_hash = (
'AA' => [ 'Financial service provider',
    'A manager of money or other assets.' ],
'AB' => [ 'Importer',
    'A person or group that imports goods or services.' ],
'AC' => [ 'Vendor',
    'A person or group selling goods or services.' ],
'AD' => [ 'Exporter',
    'A person or group who sends goods or services to a foreign country.' ],
'AG' => [ 'Agency',
    'A party or group that acts as an agent on behalf of another party.' ],
'BG' => [ 'Buying group',
    'A temporary group of buyers formed for purchasing purposes.' ],
'BR' => [ 'Broker',
    'A person or group acting as an agent for others, accepting responsibility in return for a fee.' ],
'CN' => [ 'Consolidator (master distributor)',
    'A person or group acting as a clearing house for goods or services.' ],
'DE' => [ 'Dealer',
    'A person or group buying directly from a manufacturer for resale.' ],
'DI' => [ 'Distributor',
    'A person or group acting explicitly as distributor of merchandise or goods.' ],
'JB' => [ 'Jobber',
    'A person or group buying merchandise to resell it to a retailer.' ],
'MF' => [ 'Manufacturer',
    'A company that produces goods from raw materials.' ],
'OE' => [ 'OEM (Original equipment manufacturer)',
    'A manufacturer selling its goods to a company reselling them using own labels.' ],
'RS' => [ 'Resale',
    'A class of trade where goods and/or services are purchased for resale.' ],
'RT' => [ 'Retailer',
    'A person selling goods or services in small quantities or by the piece.' ],
'ST' => [ 'Stationer',
    'The trade has a classification of stationer.' ],
'WH' => [ 'Wholesaler',
    'A person or group buying goods in large quantities for resale by a retailer.' ],
'WS' => [ 'User',
    'Identifies the end-user of goods or services.' ],
'WT' => [ 'Out patient',
    'A patient not under the full time care of a hospital but visits from time to time for treatment.' ],
'WU' => [ 'In patient',
    'A patient under the full time care of a hospital.' ],
'WV' => [ 'Electricity exchange',
    'Identifies the exchange where the intermediaries sell and buy electricity.' ],
);
sub get_codes { return \%code_hash; }

1;
