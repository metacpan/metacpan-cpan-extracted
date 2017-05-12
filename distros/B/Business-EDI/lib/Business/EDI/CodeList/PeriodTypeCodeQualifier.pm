package Business::EDI::CodeList::PeriodTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {2023;}
my $usage       = 'B';

# 2023  Period type code qualifier                              [B]
# Desc: Code qualifying the type of the period.
# Repr: an..3

my %code_hash = (
'1' => [ 'Contract period',
    'Period covered by the contract.' ],
'2' => [ 'Endorsement period',
    'Period covered by the endorsement.' ],
'3' => [ 'Contract cancellation notice period',
    'Period before which a cancellation notice must be made in order to avoid automatic renewal.' ],
'4' => [ 'Project period',
    'Period of a project.' ],
'5' => [ 'Construction period',
    'Period of construction.' ],
'6' => [ 'Test period',
    'Period during which testing occurs.' ],
);
sub get_codes { return \%code_hash; }

1;
