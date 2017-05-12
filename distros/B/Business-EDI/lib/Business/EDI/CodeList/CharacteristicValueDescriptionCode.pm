package Business::EDI::CodeList::CharacteristicValueDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7111;}
my $usage       = 'C';

# 7111  Characteristic value description code                   [C]
# Desc: Code specifying the value of a characteristic.
# Repr: an..3

my %code_hash = (
'1' => [ 'Chest/bust width',
    'The measurement around the widest part of the chest/bust.' ],
'2' => [ 'Hip width',
    'The measurement around the fullest part of the hips.' ],
'3' => [ 'Outside leg length',
    'The measurement of the outside leg seam. This is the distance from the waist to the bottom of the trousers.' ],
);
sub get_codes { return \%code_hash; }

1;
