package Business::EDI::CodeList::InterchangeRecipientIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0010";}
my $usage       = 'B';  # guessed value

# 0010 Interchange recipient identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
