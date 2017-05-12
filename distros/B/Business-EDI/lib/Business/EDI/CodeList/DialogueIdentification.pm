package Business::EDI::CodeList::DialogueIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0311";}
my $usage       = 'B';  # guessed value

# 0311 Dialogue identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
