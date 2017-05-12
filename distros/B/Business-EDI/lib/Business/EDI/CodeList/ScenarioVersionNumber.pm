package Business::EDI::CodeList::ScenarioVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0128";}
my $usage       = 'B';  # guessed value

# 0128 Scenario version number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
