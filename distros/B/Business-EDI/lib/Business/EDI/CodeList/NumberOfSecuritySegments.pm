package Business::EDI::CodeList::NumberOfSecuritySegments;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0588";}
my $usage       = 'B';  # guessed value

# 0588 Number of security segments                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
