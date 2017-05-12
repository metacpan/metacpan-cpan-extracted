package Business::EDI::CodeList::AccountingEntryTypeNameCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4475;}
my $usage       = 'B';

# 4475  Accounting entry type name code                         [B]
# Desc: Code specifying a type of accounting entry.
# Repr: an..17

my %code_hash = (
'1' => [ 'Purchase',
    'The type of accounting entry is purchase.' ],
'2' => [ 'Sale',
    'The type of accounting entry is sale.' ],
'3' => [ 'Cash',
    'The type of accounting entry is cash.' ],
'4' => [ 'Opening balance',
    'The type of accounting entry is opening balance.' ],
'5' => [ 'Miscellaneous',
    'The type is a miscellaneous accounting entry.' ],
);
sub get_codes { return \%code_hash; }

1;
