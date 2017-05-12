package Business::EDI::CodeList::InterchangeAgreementIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0032";}
my $usage       = 'B';  # guessed value

# 0032 Interchange agreement identifier                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
