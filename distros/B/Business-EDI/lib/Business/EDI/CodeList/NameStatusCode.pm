package Business::EDI::CodeList::NameStatusCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3397;}
my $usage       = 'C';

# 3397  Name status code                                        [C]
# Desc: Code specifying the status of a name.
# Repr: an..3

my %code_hash = (
'1' => [ 'Name given at birth',
    'The name of an individual assigned at birth.' ],
'2' => [ 'Current name',
    'Name currently used by the person.' ],
'3' => [ 'Previous name',
    'The previous name which was used but is no longer used by the person.' ],
'7' => [ 'Original name of an entity',
    'Identifies the name that existed in the beginning.' ],
'8' => [ 'Corrected name of an entity',
    'Identifies a name substituted for one that was wrong.' ],
'9' => [ 'Name of an entity changed to',
    'Identifies a name to which a previous name was changed.' ],
);
sub get_codes { return \%code_hash; }

1;
