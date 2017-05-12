package Business::EDI::CodeList::DamageDetailsCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7493;}
my $usage       = 'B';

# *    7493  Damage details code qualifier                           [B]
# Desc: Code qualifying the damage details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Equipment damage',
    'The damage details relate to equipment, e.g. a container.' ],
'2' => [ 'Consignment damage',
    'The damage details relate to a consignment.' ],
'3' => [ 'Means of transport damage',
    'The damage details relate to a means of transport.' ],
);
sub get_codes { return \%code_hash; }

1;
