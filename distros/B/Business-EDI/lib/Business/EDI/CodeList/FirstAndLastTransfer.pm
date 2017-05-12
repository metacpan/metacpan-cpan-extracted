package Business::EDI::CodeList::FirstAndLastTransfer;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0073";}
my $usage       = 'B';

# 0073  First and last transfer
# Desc: Indication used for the first and last message in a sequence
# of messages related to the same topic.
# Repr: a1

my %code_hash = (
'C' => [ 'Creation',
    'First transmission of a number of transfers of the same message.' ],
'F' => [ 'Final',
    'Last transmission of a number of transfers of the same message.' ],
);
sub get_codes { return \%code_hash; }

1;
