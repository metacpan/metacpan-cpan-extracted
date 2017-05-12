package Business::EDI::CodeList::InterchangeSenderInternalSubidentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0042";}
my $usage       = 'B';  # guessed value

# 0042 Interchange sender internal sub-identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
