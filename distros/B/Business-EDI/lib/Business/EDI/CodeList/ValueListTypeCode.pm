package Business::EDI::CodeList::ValueListTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1505;}
my $usage       = 'B';

# 1505  Value list type code                                    [B]
# Desc: Code specifying a type of value list.
# Repr: an..3

my %code_hash = (
'1' => [ 'Non coded list',
    'The list contains a set of non coded values.' ],
'2' => [ 'Date and time list',
    'The list contains a set of dates, dates and times, or times.' ],
'3' => [ 'Coded list',
    'The list contains a set of coded data values.' ],
'4' => [ 'Structure correspondence link',
    'The list contains a set of correspondence links between structures.' ],
'5' => [ 'Structure overlapping link',
    'The list contains a set of overlapping link values between structures.' ],
'6' => [ 'Structure historic link',
    'The list contains a set of historic link values between structures.' ],
'7' => [ 'Structure hierarchical link',
    'The list contains a set of hierarchical link values between structures.' ],
'8' => [ 'Structure group link',
    'The list contains a set of group link values between structures.' ],
'9' => [ 'Multiple hierarchical structure item',
    'The list contains a set of items at multiple hierarchical levels in a structure.' ],
'10' => [ 'Classification domain',
    'The list contains a set of items from a classification domain.' ],
'11' => [ 'Single hierarchical structure item',
    'The list contains a set of items at a single hierarchical level in a structure.' ],
);
sub get_codes { return \%code_hash; }

1;
