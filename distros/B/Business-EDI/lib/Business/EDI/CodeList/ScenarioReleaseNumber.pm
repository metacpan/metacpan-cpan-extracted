package Business::EDI::CodeList::ScenarioReleaseNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0130";}
my $usage       = 'B';  # guessed value

# 0130 Scenario release number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
