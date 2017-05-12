package Business::EDI::CodeList::SimpleDataElementCharacterRepresentationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9153;}
my $usage       = 'B';

# 9153  Simple data element character representation code       [B]
# Desc: Code specifying the character representation of a
# simple data element.
# Repr: an..3

my %code_hash = (
'1' => [ 'Alphabetic',
    'Simple data element character type is alphabetic.' ],
'2' => [ 'Alphanumeric',
    'Simple data element character type is alphanumeric.' ],
'3' => [ 'Numeric',
    'Simple data element character type is numeric.' ],
'4' => [ 'Binary',
    'Simple data element character type is binary.' ],
'5' => [ 'Date',
    'Simple data element character type is a date.' ],
'6' => [ 'Identifier',
    'Simple data element character type is an identifier.' ],
'7' => [ 'Time',
    'Simple data element character type is time.' ],
'8' => [ 'Numeric, implied decimal point of 0 places',
    'Simple data element character type is numeric with an implied decimal point of 0 places as determined from right to left.' ],
'9' => [ 'String',
    'Simple data element character type is a string.' ],
'10' => [ 'Numeric, implied decimal point of 1 place',
    'Simple data element character type is numeric with an implied decimal point of 1 place as determined from right to left.' ],
'11' => [ 'Numeric, implied decimal point of 2 places',
    'Simple data element character type is numeric with an implied decimal point of 2 places as determined from right to left.' ],
'12' => [ 'Numeric, implied decimal point of 3 places',
    'Simple data element character type is numeric with an implied decimal point of 3 places as determined from right to left.' ],
'13' => [ 'Numeric, implied decimal point of 4 places',
    'Simple data element character type is numeric with an implied decimal point of 4 places as determined from right to left.' ],
'14' => [ 'Numeric, implied decimal point of 5 places',
    'Simple data element character type is numeric with an implied decimal point of 5 places as determined from right to left.' ],
'15' => [ 'Numeric, implied decimal point of 6 places',
    'Simple data element character type is numeric with an implied decimal point of 6 places as determined from right to left.' ],
'16' => [ 'Numeric, implied decimal point of 7 places',
    'Simple data element character type is numeric with an implied decimal point of 7 places as determined from right to left.' ],
'17' => [ 'Numeric, implied decimal point of 8 places',
    'Simple data element character type is numeric with an implied decimal point of 8 places as determined from right to left.' ],
'18' => [ 'Numeric, implied decimal point of 9 places',
    'Simple data element character type is numeric with an implied decimal point of 9 places as determined from right to left.' ],
);
sub get_codes { return \%code_hash; }

1;
