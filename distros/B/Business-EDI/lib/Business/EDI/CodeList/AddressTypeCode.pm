package Business::EDI::CodeList::AddressTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3131;}
my $usage       = 'C';

# 3131  Address type code                                       [C]
# Desc: Code specifying the type of an address.
# Repr: an..3

my %code_hash = (
'1' => [ 'Postal address',
    'The address is representing a postal address.' ],
'2' => [ 'Fiscal address',
    'Identification of an address as required by fiscal administrations.' ],
'3' => [ 'Physical address',
    'The address represents an actual physical location.' ],
);
sub get_codes { return \%code_hash; }

1;
