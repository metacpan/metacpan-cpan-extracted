package Business::EDI::CodeList::AddressFormatCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3477;}
my $usage       = 'C';

# 3477  Address format code                                     [C]
# Desc: Code specifying the format of an address.
# Repr: an..3

my %code_hash = (
'1' => [ 'Street name followed by number',
    'Address street name followed by address number.' ],
'2' => [ 'Number, road type, road name in this sequence',
    'House number followed by type of road and name of the road.' ],
'3' => [ 'Road type, road name, number in this sequence',
    'Type of the road followed by name of the road and the house number.' ],
'4' => [ 'Post office box',
    'Post office box.' ],
'5' => [ 'Unstructured address',
    'Unstructured address, comprising an unspecified mix of components.' ],
'6' => [ 'Street name followed by number, building, suite',
    'Identifies the address component as street name followed by number, building, and suite in this sequence.' ],
'7' => [ 'Rural route number',
    'Identifies the address component as the rural route number.' ],
'8' => [ 'Post office drawer number',
    'Identifies the address component as the post office drawer.' ],
'9' => [ 'Building name followed by suite',
    'Identifies the address component as building followed by suite.' ],
);
sub get_codes { return \%code_hash; }

1;
