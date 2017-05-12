package Business::EDI::CodeList::FrequencyCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2013;}
my $usage       = 'C';

# 2013  Frequency code                                          [C]
# Desc: Code specifying the rate of recurrence.
# Repr: an..3

my %code_hash = (
'A' => [ 'Annually (calendar year)',
    'Code defining a yearly forecast.' ],
'B' => [ 'Continuous',
    'Flexible frequency scheduling based on continuous consumption of items.' ],
'C' => [ 'Synchronous',
    'Flexible frequency scheduling based on synchronous consumption of items.' ],
'D' => [ 'Discrete',
    'Flexible frequency according to planning process.' ],
'E' => [ 'Replenishment',
    'Flexible frequency scheduling based on replenishment of the consumption of items.' ],
'F' => [ 'Flexible interval (from date X through date Y)',
    'Code defining a forecasted usage that is planned between two defined dates.' ],
'G' => [ 'Ten days',
    'Ten day interval.' ],
'H' => [ 'Semi-monthly',
    'Half month interval.' ],
'J' => [ 'Just-in-time',
    'Scheduling based on just-in-time of the need.' ],
'M' => [ 'Monthly (calendar months)',
    'Code defining a forecast by calendar month(s).' ],
'Q' => [ 'Quarterly (calendar quarters)',
    'Code defining a forecast by calendar quarter(s). (Jan- Mar, Apr-Jun, Jul-Sep, Oct-Dec).' ],
'S' => [ 'Semi-annually (calendar year)',
    'Code defining a forecast for the first six months of the year or the second six months of the year.' ],
'T' => [ 'Four week period (13 periods per year)',
    'Code defining a forecast for four week intervals.' ],
'W' => [ 'Weekly',
    'Code defining a forecast for weekly intervals.' ],
'Y' => [ 'Daily',
    'Code defining a schedule by day.' ],
'ZZZ' => [ 'Mutually defined',
    'Code reserved for special trading partner requirements when pre-defined codes do not exist.' ],
);
sub get_codes { return \%code_hash; }

1;
