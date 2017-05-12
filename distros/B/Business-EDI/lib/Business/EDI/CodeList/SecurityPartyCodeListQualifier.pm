package Business::EDI::CodeList::SecurityPartyCodeListQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0513";}
my $usage       = 'B';

# 0513  Security party code list qualifier
# Desc: Identification of the type of identification used to register
# the security parties.
# Repr: an..3

my %code_hash = (
'1' => [ 'ACH',
    'Automated clearing house identification.' ],
'2' => [ 'GS1',
    'GS1, an international organization of GS1 Member Organizations that manages the GS1 System.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
