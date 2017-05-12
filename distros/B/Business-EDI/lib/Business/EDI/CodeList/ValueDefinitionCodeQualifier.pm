package Business::EDI::CodeList::ValueDefinitionCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9029;}
my $usage       = 'B';

# 9029  Value definition code qualifier                         [B]
# Desc: Code qualifying a value definition.
# Repr: an..3

my %code_hash = (
'1' => [ 'Pattern',
    'The value definition is a pattern.' ],
'2' => [ 'Minimum',
    'The value definition is a minimum.' ],
'3' => [ 'Specific value',
    'The value definition is a specific value.' ],
'4' => [ 'Maximum',
    'The value definition is a maximum.' ],
'5' => [ 'Default',
    'The value definition is a default.' ],
);
sub get_codes { return \%code_hash; }

1;
