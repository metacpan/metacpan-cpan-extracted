package Business::EDI::CodeList::ObjectTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7495;}
my $usage       = 'B';

# 7495  Object type code qualifier                              [B]
# Desc: Code qualifying a type of object.
# Repr: an..3

my %code_hash = (
'1' => [ 'Value list',
    'A coded or non coded list of values.' ],
'2' => [ 'Name value in list',
    'A specific name value in a list.' ],
'3' => [ 'Footnote',
    'Explanatory note.' ],
'4' => [ 'Code value',
    'A specific code value in a value list.' ],
'5' => [ 'Data set structure',
    'A data set structure definition.' ],
'6' => [ 'Statistical concept',
    'A statistical concept.' ],
'7' => [ 'Array segment presentation',
    'The way the array is presented in the segment containing the array data.' ],
'8' => [ 'Data set scope',
    'The scope definition of a data set.' ],
'9' => [ 'Message number assigned by party',
    'The identity given to a message by a specified party.' ],
'10' => [ 'Linked source tree structure level',
    'A level in a tree structure that is the source level in a link.' ],
'11' => [ 'Linked source tree structure',
    'A structure containing two or more objects in a hierarchy that is the source structure in a link.' ],
'12' => [ 'Linked source item',
    'An item that is the source item in a link.' ],
'13' => [ 'Linked target tree structure level',
    'A level in a tree structure that is the target level in a link.' ],
'14' => [ 'Linked target tree structure',
    'A structure containing two or more objects in a hierarchy that is the target structure in a link.' ],
'15' => [ 'Linked target item',
    'An item that is the target item in a link.' ],
'16' => [ 'Work breakdown structure',
    'The index used to identify the reporting structure references assigned to work tasks.' ],
'17' => [ 'Organization breakdown structure',
    'The index used to identify the reporting structure references that indicate who is responsible for getting work done and who is performing work.' ],
'18' => [ 'Cost element structure',
    'The index used to identify the reporting structure references assigned to cost elements or resources used to perform work.' ],
'19' => [ 'Coded attribute',
    'An attribute that is coded.' ],
'20' => [ 'Uncoded attribute',
    'An attribute that is uncoded.' ],
'21' => [ 'Package',
    'The object being maintained is a package.' ],
'22' => [ 'Tool',
    'The object being maintained is a tool.' ],
'23' => [ 'Equipment',
    'The object being maintained is a piece of equipment.' ],
'24' => [ 'Transaction',
    'The object is a transaction.' ],
);
sub get_codes { return \%code_hash; }

1;
