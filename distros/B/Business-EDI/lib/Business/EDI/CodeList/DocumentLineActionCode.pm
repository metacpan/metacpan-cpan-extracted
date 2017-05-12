package Business::EDI::CodeList::DocumentLineActionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1073;}
my $usage       = 'B';

# 1073  Document line action code                               [B]
# Desc: Code indicating an action associated with a line of a
# document.
# Repr: an..3

my %code_hash = (
'1' => [ 'Included in document/transaction',
    'The document line is included in the document/transaction.' ],
'2' => [ 'Excluded from document/transaction',
    'The document line is excluded from the document/transaction.' ],
);
sub get_codes { return \%code_hash; }

1;
