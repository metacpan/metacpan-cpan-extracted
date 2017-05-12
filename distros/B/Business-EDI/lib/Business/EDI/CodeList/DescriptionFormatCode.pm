package Business::EDI::CodeList::DescriptionFormatCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7077;}
my $usage       = 'B';

# 7077  Description format code                                 [B]
# Desc: Code specifying the format of a description.
# Repr: an..3

my %code_hash = (
'A' => [ 'Free-form long description',
    'Long description of an item in free form.' ],
'B' => [ 'Code and text',
    'Description of an item in coded and free form text.' ],
'C' => [ 'Code (from industry code list)',
    'Description of an item in coded format.' ],
'D' => [ 'Free-form price look up',
    'Price look-up description of a product for point of sale receipts.' ],
'E' => [ 'Free-form short description',
    'Short description of an item in free form.' ],
'F' => [ 'Free-form',
    'Description of an item in free form text.' ],
'S' => [ 'Structured (from industry code list)',
    'Description of an item in a structured format.' ],
'X' => [ 'Semi-structured (code + text)',
    'Description of an item in a coded and free text format.' ],
);
sub get_codes { return \%code_hash; }

1;
