package Business::EDI::CodeList::ClassTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7059;}
my $usage       = 'B';

# 7059  Class type code                                         [B]
# Desc: Code specifying the type of class.
# Repr: an..3

my %code_hash = (
'1' => [ 'Chemistry',
    'The class of chemical properties.' ],
'2' => [ 'Mechanical',
    'Mechanical properties.' ],
'3' => [ 'Component of measurable quantity',
    'Component being quantitatively measured (such as height).' ],
'4' => [ 'System of measurable quantity',
    'System being investigated to obtain a measurable quantity (such as blood serum).' ],
'5' => [ 'Ecological labelling',
    'Characteristic of ecological labelling.' ],
'6' => [ 'Party characteristic',
    'Characteristic of a party.' ],
'7' => [ 'Magnetic',
    'The property is magnetic.' ],
'8' => [ 'Meter',
    'A class of characteristics describing a meter.' ],
'9' => [ 'Meter reading',
    'A class of characteristics describing a meter reading.' ],
'10' => [ 'Unspecified',
    'No specific class.' ],
'11' => [ 'Product',
    'A class of characteristics describing a product.' ],
'12' => [ 'Medical investigation',
    'The class describes a medical investigation.' ],
'13' => [ 'Animal species',
    'The class describes the species of an animal.' ],
'14' => [ 'Animal breed',
    'The class describes the breed of an animal species.' ],
'15' => [ 'Structure',
    'Property of a structure.' ],
'16' => [ 'Parameter',
    'Property of a parameter.' ],
'17' => [ 'Equipment',
    'A class of characteristics describing an equipment.' ],
'18' => [ 'Process',
    'A class of characteristics describing a process.' ],
);
sub get_codes { return \%code_hash; }

1;
