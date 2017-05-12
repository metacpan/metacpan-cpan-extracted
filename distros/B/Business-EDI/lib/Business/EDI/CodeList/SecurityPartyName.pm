package Business::EDI::CodeList::SecurityPartyName;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0586";}
my $usage       = 'B';  # guessed value

# 0586 Security party name                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
