package Business::EDI::CodeList::RangeTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6167;}
my $usage       = 'B';

# 6167  Range type code qualifier                               [B]
# Desc: Code qualifying a type of range.
# Repr: an..3

my %code_hash = (
'1' => [ 'Allowance range',
    'Identifies the range for an allowance.' ],
'2' => [ 'Charge range',
    'Identifies the range for a charge.' ],
'3' => [ 'Monetary range',
    'Identifies the range related to money.' ],
'4' => [ 'Quantity range',
    'Identifies the range for quantity.' ],
'5' => [ 'Temperature range',
    'The range of a temperature.' ],
'6' => [ 'Order quantity range',
    'The minimum to maximum order quantity.' ],
'7' => [ 'Delivery quantity range',
    'The minimum to maximum delivery quantity.' ],
'8' => [ 'Production batch range',
    'The minimum to maximum quantity in a single production run.' ],
'9' => [ 'Monthly quantity range',
    'The minimum to maximum monthly quantity.' ],
'10' => [ 'Annual quantity range',
    'The minimum to maximum yearly quantity.' ],
'11' => [ 'Package stacking range',
    'Range in which packages can be stacked.' ],
'12' => [ 'Transport temperature range',
    'The temperature range at which cargo is to be kept while it is under transport.' ],
'13' => [ 'Equipment pre-tripping temperature range',
    'The temperature range at which the equipment is to be brought to in preparation for the loading of cargo.' ],
'14' => [ 'Terms discount range',
    'Identifies the range for a terms discount.' ],
'15' => [ 'Order quantity range, cumulative',
    'The minimum to maximum cumulative order quantity.' ],
'16' => [ 'Equipment number range',
    'Range of equipment numbers.' ],
);
sub get_codes { return \%code_hash; }

1;
