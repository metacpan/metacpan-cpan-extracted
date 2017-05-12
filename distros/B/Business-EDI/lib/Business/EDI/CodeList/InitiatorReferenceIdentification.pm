package Business::EDI::CodeList::InitiatorReferenceIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0303";}
my $usage       = 'B';  # guessed value

# 0303 Initiator reference identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
