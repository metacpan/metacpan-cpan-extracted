package Business::EDI::CodeList::InterchangeRecipientInternalSubidentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0046";}
my $usage       = 'B';  # guessed value

# 0046 Interchange recipient internal sub-identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
