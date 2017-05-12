package Business::EDI::CodeList::DataRepresentationTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9169;}
my $usage       = 'B';

# 9169  Data representation type code                           [B]
# Desc: Code specifying a type of data representation.
# Repr: an..3

my %code_hash = (
'1' => [ 'Byte',
    'Data representation is a byte.' ],
'2' => [ 'Character',
    'Data representation is a character.' ],
'3' => [ 'Enumerated type',
    'Data representation is an enumerated type.' ],
'4' => [ '32-bit floating point number',
    'Data representation is 32-bit floating point number.' ],
'5' => [ '64-bit floating point number',
    'Data representation is a 64-bit floating point number.' ],
'6' => [ 'Generic floating point number',
    'Data representation is a generic floating point number.' ],
'7' => [ '16-bit integer',
    'Data representation is a 16-bit integer.' ],
'8' => [ '32-bit integer',
    'Data representation is a 32-bit integer.' ],
'9' => [ '64-bit integer',
    'Data representation is a 64-bit integer.' ],
'10' => [ '8-bit integer',
    'Data representation is an 8-bit integer.' ],
'11' => [ 'Generic integer',
    'Data representation is a generic integer.' ],
'12' => [ 'String',
    'Data representation is a string.' ],
);
sub get_codes { return \%code_hash; }

1;
