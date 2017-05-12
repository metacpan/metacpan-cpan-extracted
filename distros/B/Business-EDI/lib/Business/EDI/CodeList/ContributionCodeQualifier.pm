package Business::EDI::CodeList::ContributionCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5047;}
my $usage       = 'B';

# 5047  Contribution code qualifier                             [B]
# Desc: Code qualifying a contribution.
# Repr: an..3

my %code_hash = (
'1' => [ 'Normal',
    'As normally agreed between parties.' ],
'2' => [ 'Special',
    'A contribution not usually made.' ],
'3' => [ 'Reversal',
    'Reversing a previous contribution.' ],
'4' => [ 'Back payment',
    'Payment is a period prior to the normal period.' ],
'5' => [ 'Advanced payment',
    'Payment is for a period post the normal period.' ],
'6' => [ 'Ceasing contributions',
    'Payment is irregular as contributions ceased from the specified date.' ],
'ZZZ' => [ 'Mutually defined',
    'Mutually defined contribution qualifier.' ],
);
sub get_codes { return \%code_hash; }

1;
