package Business::EDI::CodeList::StatisticTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6331;}
my $usage       = 'B';

# 6331  Statistic type code qualifier                           [B]
# Desc: Code qualifying the type of a statistic.
# Repr: an..3

my %code_hash = (
'1' => [ 'Mean average',
    'The type of statistic being reported is the mean average.' ],
'2' => [ 'Median',
    'The type of statistic being reported is the middle value of a series.' ],
'3' => [ 'Estimate',
    'The type of statistic being reported is an approximate judgement.' ],
'4' => [ 'Efficiency performance',
    'The type of statistic being reported is efficiency performance.' ],
'5' => [ 'Process capability upper',
    'The statistic being reported is the upper process capability.' ],
'6' => [ 'Process capability lower',
    'The statistic being reported is the lower process capability.' ],
'8' => [ 'Range average',
    'The type of statistic being reported is the range average.' ],
'9' => [ 'Standard deviation',
    'The type of statistic being reported is the standard deviation.' ],
'10' => [ 'In limits',
    'The type of statistic being reported is within limits.' ],
);
sub get_codes { return \%code_hash; }

1;
