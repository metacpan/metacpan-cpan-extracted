package Business::EDI::CodeList::AddressStatusCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3475;}
my $usage       = 'C';

# 3475  Address status code                                     [C]
# Desc: Code specifying the status of an address.
# Repr: an..3

my %code_hash = (
'1' => [ 'Permanent address',
    'The address is the permanent address.' ],
'2' => [ 'Current address',
    'Current address.' ],
'4' => [ 'Previous address',
    'The previous address.' ],
'5' => [ 'Former address',
    'A former address.' ],
'6' => [ 'Temporary address',
    'An address temporarily used.' ],
);
sub get_codes { return \%code_hash; }

1;
