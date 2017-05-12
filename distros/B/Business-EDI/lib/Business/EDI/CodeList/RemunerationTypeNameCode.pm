package Business::EDI::CodeList::RemunerationTypeNameCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5315;}
my $usage       = 'B';

# 5315  Remuneration type name code                             [B]
# Desc: Code specifying the name of a type of remuneration.
# Repr: an..3

my %code_hash = (
'1' => [ 'Minimum guaranteed wages',
    'Minimum guaranteed wages.' ],
'2' => [ 'Basic remuneration',
    'Basic remuneration.' ],
'3' => [ 'Net wages',
    'Net wages.' ],
);
sub get_codes { return \%code_hash; }

1;
