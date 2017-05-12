package Business::EDI::CodeList::ErroneousDataElementPositionInSegment;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0098";}
my $usage       = 'B';  # guessed value

# 0098 Erroneous data element position in segment                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
