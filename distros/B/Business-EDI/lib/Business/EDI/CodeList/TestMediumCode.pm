package Business::EDI::CodeList::TestMediumCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3077;}
my $usage       = 'B';

# 3077  Test medium code                                        [B]
# Desc: Code specifying the medium on which a test was or is
# to be applied.
# Repr: an..3

my %code_hash = (
'1' => [ 'Animal',
    'Specifies the medium being tested is an animal.' ],
'2' => [ 'Human',
    'Specifies the medium being tested is a human.' ],
'3' => [ 'Sulphide',
    'Specifies that the medium being tested is the sulphide component.' ],
'4' => [ 'Aluminate',
    'Specifies that the medium being tested is the aluminate component.' ],
'5' => [ 'Silicate',
    'Specifies that the medium being tested is the silicate component.' ],
'6' => [ 'Oxide',
    'Specifies that the medium being tested is the oxide component.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list whose meaning is agreed among partners to be used on an interim basis until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
