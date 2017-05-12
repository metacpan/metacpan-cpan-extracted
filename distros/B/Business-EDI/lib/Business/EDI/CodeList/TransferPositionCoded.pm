package Business::EDI::CodeList::TransferPositionCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0323";}
my $usage       = 'B';

# 0323  Transfer position, coded
# Desc: Indication of the position of a transfer.
# Repr: a1

my %code_hash = (
'F' => [ 'First message',
    'First message in sequence. Can only appear once at the start of the sequence.' ],
'I' => [ 'Intermediate message',
    'Intermediate message in sequence. May appear zero or more times within the sequence.' ],
'L' => [ 'Last message',
    'Last message in sequence. Can appear only once at the end of the sequence.' ],
);
sub get_codes { return \%code_hash; }

1;
