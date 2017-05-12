package Business::EDI::CodeList::ProductIdentifierCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4347;}
my $usage       = 'B';

# 4347  Product identifier code qualifier                       [B]
# Desc: Code qualifying the product identifier.
# Repr: an..3

my %code_hash = (
'1' => [ 'Additional identification',
    'Information which specifies and qualifies product identifications.' ],
'2' => [ 'Identification for potential substitution',
    'The item number describes the potential substitute product.' ],
'3' => [ 'Substituted by',
    'The given item number is the number of the product that substitutes another one.' ],
'4' => [ 'Substituted for',
    'The given item number is the number of the original product substituted by another.' ],
'5' => [ 'Product identification',
    'The item number is for product identification.' ],
'6' => [ 'Successor product id',
    'Product id of the product that will follow the one currently in production/trade.' ],
'7' => [ 'Predecessor product id',
    'Product id of the predecessor of the product currently in production/trade.' ],
'8' => [ 'Expired/out of production',
    'The given item number is the expired item number of the product. It has been replaced.' ],
'9' => [ 'Deletion of secondary identification',
    'Code indicating the deletion of a secondary identification.' ],
'10' => [ "Defective part's identification",
    'Identification of a defective part.' ],
'11' => [ "Repaired part's identification",
    'Identification of a repaired part.' ],
'12' => [ 'Alternate product identification',
    'Alternate number to identify the product.' ],
'13' => [ 'Non-promotional item',
    'Used to indicate which trade item the promotional trade item replaces or coexists alongside. To enable the identification of the two trade items to be linked providing access to their information.' ],
);
sub get_codes { return \%code_hash; }

1;
