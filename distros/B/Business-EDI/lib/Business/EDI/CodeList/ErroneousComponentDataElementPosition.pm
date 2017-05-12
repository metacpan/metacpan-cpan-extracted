package Business::EDI::CodeList::ErroneousComponentDataElementPosition;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0104";}
my $usage       = 'B';  # guessed value

# 0104 Erroneous component data element position                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
