package Business::EDI::CodeList::UnitTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6353;}
my $usage       = 'C';

# 6353  Unit type code qualifier                                [C]
# Desc: Code qualifying the type of unit.
# Repr: an..3

my %code_hash = (
'1' => [ 'Number of pricing units',
    'Number of units which multiplied by the unit price gives price.' ],
'2' => [ 'Transportable unit',
    'A unit that is capable of being transported.' ],
'3' => [ 'Number of debit units',
    'The number of units which are debited by the sender of the consignment to the receiving party.' ],
'4' => [ 'Number of received units',
    'The number of units which are received by the receiving party of the consignment.' ],
'5' => [ 'Number of free days for container availability',
    'Number of days within which the container will be made available at no charge.' ],
'6' => [ 'Number of structure components',
    'Number of components in a structure.' ],
'7' => [ 'Number of asset units',
    'The number of units of an asset.' ],
'8' => [ 'Number of consignments',
    'The number of consignments.' ],
'9' => [ 'Adult',
    'The unit is an adult.' ],
'10' => [ 'Child',
    'The unit is a child.' ],
'11' => [ 'Number of trial balance accounts',
    'The unit is trial balance account.' ],
'12' => [ 'Number of lines',
    'Unit is line.' ],
'13' => [ 'Senior citizen',
    'The unit is a senior citizen.' ],
);
sub get_codes { return \%code_hash; }

1;
