package Business::EDI::CodeList::InterchangeSenderInternalIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0008";}
my $usage       = 'B';  # guessed value

# 0008 Interchange sender internal identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
