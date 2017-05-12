package Business::EDI::CodeList::TermsTimeRelationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2009;}
my $usage       = 'B';

# 2009  Terms time relation code                                [B]
# Desc: Code relating terms to a reference date, time or
# period.
# Repr: an..3

my %code_hash = (
'1' => [ 'Reference date',
    'Payment terms related to reference date.' ],
'2' => [ 'Before reference',
    'Payment terms related to time before reference date.' ],
'3' => [ 'After reference',
    'Payment terms related to time after reference date.' ],
'4' => [ 'End of 10-day period containing the reference date',
    'Payment terms are at the end of the ten day period containing the reference date.' ],
'5' => [ 'End of 2-week period containing the reference date',
    'Payment terms are at the end of the two week period containing the reference date.' ],
'6' => [ 'End of month containing the reference date',
    'Payment terms are at the end of the month containing the reference date.' ],
'7' => [ 'End of the month following the month of reference date',
    'Payment terms are at the end of the month following the month of reference date.' ],
'8' => [ 'End of quarter containing the reference date',
    'Payment terms are at the end of the quarter containing the reference date.' ],
'9' => [ 'End of year containing the reference date',
    'Payment terms are at the end of the year containing the reference date.' ],
'10' => [ 'End of week containing the reference date',
    'Payment terms are at the end of the week containing the reference date.' ],
'11' => [ 'End of ten day period following month after reference',
    "date's month Payment terms are 10 days after the end of the referenced month." ],
'12' => [ 'End of half year containing the reference date',
    'End of the half year in which the referred date falls.' ],
'13' => [ 'From reference',
    'Payment terms related to a time inclusive of and after a reference date.' ],
'14' => [ 'End of 15-day period containing the reference date',
    'Payment terms are at the end of the 15-day period containing the reference date.' ],
'15' => [ 'On or before reference',
    'Payment terms are on or before.' ],
'16' => [ 'Whichever is first, the 15th or last day of the month',
    'following the payment terms period The payment terms are at, whichever is first, the 15th or the last day of the month following the payment terms period (payment terms period = period of time between the reference date and the theoretical due date).' ],
'17' => [ 'After end of month containing the reference date',
    'Payment terms related to a time after the end of the month containing the reference date.' ],
);
sub get_codes { return \%code_hash; }

1;
