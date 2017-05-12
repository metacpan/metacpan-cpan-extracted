package Business::EDI::CodeList::ScenarioIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0127";}
my $usage       = 'B';  # guessed value

# 0127 Scenario identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
