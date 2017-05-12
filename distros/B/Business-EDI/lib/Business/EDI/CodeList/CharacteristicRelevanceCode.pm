package Business::EDI::CodeList::CharacteristicRelevanceCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4051;}
my $usage       = 'B';

# 4051  Characteristic relevance code                           [B]
# Desc: Code specifying the relevance of a characteristic.
# Repr: an..3

my %code_hash = (
'1' => [ 'Information only',
    'This product characteristic provides additional information for customer.' ],
'2' => [ 'Required within orders',
    'This product characteristic has to be provided within orders.' ],
'3' => [ 'Requirement for subsequent business transactions',
    'This product characteristic has to be provided within the subsequent business transactions.' ],
);
sub get_codes { return \%code_hash; }

1;
