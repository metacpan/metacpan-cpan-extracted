package Business::EDI::CodeList::PriorityDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4037;}
my $usage       = 'B';

# 4037  Priority description code                               [B]
# Desc: Code specifying a priority.
# Repr: an..3

my %code_hash = (
'1' => [ 'Immediate',
    'To be done immediately.' ],
'2' => [ 'Urgent',
    'To be performed before any non-urgent task.' ],
'3' => [ 'Normal',
    'To be done as routine work.' ],
'4' => [ 'Scheduled',
    'To be done as part of a scheduled plan.' ],
'5' => [ 'Category A',
    'Priority is category A.' ],
'6' => [ 'Category B',
    'Priority is category B.' ],
);
sub get_codes { return \%code_hash; }

1;
