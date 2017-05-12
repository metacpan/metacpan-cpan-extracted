package Business::EDI::CodeList::RatePlanCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5501;}
my $usage       = 'I';

# 5501  Rate plan code                                          [I]
# Desc: Code specifying a rate plan.
# Repr: an..3

my %code_hash = (
'1' => [ 'Hourly',
    'Rate is per hour.' ],
'2' => [ 'Total',
    'Total rate charged for the duration of the provided service which includes taxes, surcharges, drop fees and optional charges.' ],
'3' => [ 'Daily',
    'Rate is per day.' ],
'4' => [ 'Monthly',
    'Rate is per month.' ],
'5' => [ 'Weekend',
    'Rate is per weekend.' ],
'6' => [ 'Weekly',
    'Rate is per week.' ],
);
sub get_codes { return \%code_hash; }

1;
