package Business::EDI::CodeList::RateOrTariffClassDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5243;}
my $usage       = 'C';

# 5243  Rate or tariff class description code                   [C]
# Desc: Code specifying an applicable rate or tariff class.
# Repr: an..9

my %code_hash = (
'A' => [ 'Senior person rate',
    'Rate class applies to senior persons.' ],
'B' => [ 'Basic',
    'Code specifying that the rate or tariff is a basic one.' ],
'C' => [ 'Specific commodity rate',
    'Code specifying the specific commodity rate.' ],
'D' => [ 'Teenager rate',
    'Rate class applies to teenagers.' ],
'E' => [ 'Child rate',
    'Rate class applies to children.' ],
'F' => [ 'Adult rate',
    'Rate class applies to adults.' ],
'K' => [ 'Rate per kilogram',
    'Code specifying the rate per kilogram.' ],
'M' => [ 'Minimum charge rate',
    'Code specifying the minimum charge rate.' ],
'N' => [ 'Normal rate',
    'Code specifying the normal rate.' ],
'Q' => [ 'Quantity rate',
    'Code specifying the quantity rate.' ],
'R' => [ 'Class rate (Reduction on normal rate)',
    'Code specifying the reduction on normal rate.' ],
'S' => [ 'Class rate (Surcharge on normal rate)',
    'Code specifying the surcharge on normal rate.' ],
);
sub get_codes { return \%code_hash; }

1;
