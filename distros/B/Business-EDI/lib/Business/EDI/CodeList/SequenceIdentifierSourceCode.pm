package Business::EDI::CodeList::SequenceIdentifierSourceCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1159;}
my $usage       = 'B';

# 1159  Sequence identifier source code                         [B]
# Desc: Code specifying the source of a sequence identifier.
# Repr: an..3

my %code_hash = (
'1' => [ 'Broadcast 1',
    'Report from workstation 1.' ],
'2' => [ 'Broadcast 2',
    'Report from workstation 2.' ],
'3' => [ 'Manufacturer sequence number',
    "The manufacturer's plant requesting the delivery of the item has allocated the sequence number." ],
'4' => [ 'Manufacturer production sequence number',
    'The plant requesting the delivery of an item assigns a number indicating the sequence of the finished article.' ],
'5' => [ 'Transmission sequence',
    'The positional sequence when transmitted.' ],
'6' => [ 'Structure sequence',
    'The positional sequence in a message structure as published in a particular UN directory.' ],
);
sub get_codes { return \%code_hash; }

1;
