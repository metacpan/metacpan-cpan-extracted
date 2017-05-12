package Business::EDI::CodeList::ChargePeriodTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2155;}
my $usage       = 'I';

# 2155  Charge period type code                                 [I]
# Desc: Code specifying a type of a charge period.
# Repr: an..3

my %code_hash = (
'1' => [ 'Per day',
    'The associated charge applies to each day the service is provided.' ],
'2' => [ 'Per week',
    'The associated charge applies to each week the service is provided.' ],
'3' => [ 'Per month',
    'The associated charge applies to each month the service is provided.' ],
'4' => [ 'Per rental',
    'The associated charge applies to the entire length of time the service is provided.' ],
'5' => [ 'Per hour',
    'The associated charge applies to each hour the service is provided.' ],
'6' => [ 'Per minute',
    'The associated charge applies to each minute the service is provided.' ],
);
sub get_codes { return \%code_hash; }

1;
