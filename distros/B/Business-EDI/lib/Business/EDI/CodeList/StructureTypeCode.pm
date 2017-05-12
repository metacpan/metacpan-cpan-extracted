package Business::EDI::CodeList::StructureTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7515;}
my $usage       = 'B';

# 7515  Structure type code                                     [B]
# Desc: Code specifying a type of structure.
# Repr: an..3

my %code_hash = (
'1' => [ 'Cardinal array',
    'Component is represented as a cardinal array.' ],
'2' => [ 'Ordinal array',
    'Component is represented as an ordinal array.' ],
'3' => [ 'Simple value',
    'Component is represented as a simple value.' ],
'4' => [ 'Table',
    'Component is represented as a table.' ],
);
sub get_codes { return \%code_hash; }

1;
