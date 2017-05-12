package Business::EDI::CodeList::AssociationAssignedCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0057";}
my $usage       = 'B';  # guessed value

# 0057 Association assigned code                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
