package Business::EDI::CodeList::LengthOfObjectInOctetsOfBits;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0810";}
my $usage       = 'B';  # guessed value

# 0810 Length of object in octets of bits                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
