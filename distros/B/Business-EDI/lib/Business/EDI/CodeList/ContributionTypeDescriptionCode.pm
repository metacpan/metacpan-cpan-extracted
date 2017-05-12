package Business::EDI::CodeList::ContributionTypeDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5049;}
my $usage       = 'B';

# 5049  Contribution type description code                      [B]
# Desc: Code specifying a type of contribution scheme.
# Repr: an..3

my %code_hash = (
'1' => [ 'Company',
    'Company payment.' ],
'2' => [ 'Company award',
    'Company payment as per an industry or similar industrial award agreement.' ],
'3' => [ 'Company over-award',
    'Company payment which is higher than an industry or similar award agreement.' ],
'4' => [ 'Lump sum',
    'Payment is in the form of a single payment.' ],
'5' => [ 'Company additional',
    'Additional company payment.' ],
'6' => [ 'Company voluntary',
    'A company payment which is paid on a voluntary basis.' ],
'7' => [ 'Member voluntary',
    'A member payment which is paid on a voluntary basis.' ],
'8' => [ 'Member additional',
    'Additional member payment.' ],
'9' => [ 'Member individual',
    'Single payment by an individual member.' ],
'10' => [ 'Group',
    'Payment as part of a group plan or scheme.' ],
'11' => [ 'Other',
    'Contribution type differs from any of the other coded values.' ],
'ZZZ' => [ 'Mutually defined',
    'Mutually defined contribution type.' ],
);
sub get_codes { return \%code_hash; }

1;
