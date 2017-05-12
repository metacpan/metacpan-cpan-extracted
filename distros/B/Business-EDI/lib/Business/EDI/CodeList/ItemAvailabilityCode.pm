package Business::EDI::CodeList::ItemAvailabilityCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7011;}
my $usage       = 'B';

# 7011  Item availability code                                  [B]
# Desc: Code specifying the availability of an item.
# Repr: an..3

my %code_hash = (
'1' => [ 'New, announcement only',
    'The item is announced only, not yet available.' ],
'2' => [ 'New, available',
    'The item is new and available.' ],
'3' => [ 'Obsolete',
    'The item is obsolete.' ],
'4' => [ 'Prototype',
    'The item is a prototype and is not yet in normal production.' ],
'5' => [ 'Commodity',
    "Company's standard product." ],
'6' => [ 'Special',
    'Item is not a standard product.' ],
'7' => [ 'Temporarily out',
    'Item is temporarily not available.' ],
'8' => [ 'Manufacture out',
    'Item is out of production.' ],
'9' => [ 'Discontinued',
    'Item is no longer available because it is discontinued.' ],
'10' => [ 'Seasonally available only',
    'Item is only seasonally available.' ],
'11' => [ 'Deletion, announcement only',
    'The announcement of a deletion.' ],
);
sub get_codes { return \%code_hash; }

1;
