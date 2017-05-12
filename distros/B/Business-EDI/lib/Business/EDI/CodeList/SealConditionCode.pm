package Business::EDI::CodeList::SealConditionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4517;}
my $usage       = 'B';

# 4517  Seal condition code                                     [B]
# Desc: Code specifying the condition of a seal.
# Repr: an..3

my %code_hash = (
'1' => [ 'In right condition',
    'The seal is in right condition.' ],
'2' => [ 'Damaged',
    'The seal is damaged.' ],
'3' => [ 'Missing',
    'A seal that is missing.' ],
'4' => [ 'Broken',
    'Used to specify that the seal is broken.' ],
'5' => [ 'Faulty electronic seal',
    'The electronic seal is faulty.' ],
);
sub get_codes { return \%code_hash; }

1;
