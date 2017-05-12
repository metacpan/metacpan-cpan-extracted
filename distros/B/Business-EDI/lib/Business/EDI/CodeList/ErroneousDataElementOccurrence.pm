package Business::EDI::CodeList::ErroneousDataElementOccurrence;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0136";}
my $usage       = 'B';  # guessed value

# 0136 Erroneous data element occurrence                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
