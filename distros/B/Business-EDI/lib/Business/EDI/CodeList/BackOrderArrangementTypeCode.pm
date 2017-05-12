package Business::EDI::CodeList::BackOrderArrangementTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4455;}
my $usage       = 'B';

# 4455  Back order arrangement type code                        [B]
# Desc: Code specifying a type of back order arrangement.
# Repr: an..3

my %code_hash = (
'B' => [ 'Back order only if new item (book industry - not yet',
    'published only) Item on back order due to unpublished status.' ],
'F' => [ 'Factory ship',
    'Ship directly from factory to purchaser.' ],
'N' => [ 'No back order',
    'Back order is unacceptable.' ],
'W' => [ 'Warehouse ship',
    'Ship directly from warehouse.' ],
'Y' => [ 'Back order if out of stock',
    'Acceptable to put on back order if out of stock.' ],
'ZZZ' => [ 'Mutually defined',
    'A code assigned within a code list to be used on an interim basis and as defined among trading partners until a precise code can be assigned to the code list.' ],
);
sub get_codes { return \%code_hash; }

1;
