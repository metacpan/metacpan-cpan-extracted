package Business::EDI::CodeList::InterchangeSenderIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0004";}
my $usage       = 'B';  # guessed value

# 0004 Interchange sender identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
