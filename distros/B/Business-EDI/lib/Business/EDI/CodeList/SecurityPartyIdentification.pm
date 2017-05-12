package Business::EDI::CodeList::SecurityPartyIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0511";}
my $usage       = 'B';  # guessed value

# 0511 Security party identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
