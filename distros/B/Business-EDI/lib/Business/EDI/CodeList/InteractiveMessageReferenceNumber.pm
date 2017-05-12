package Business::EDI::CodeList::InteractiveMessageReferenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0340";}
my $usage       = 'B';  # guessed value

# 0340 Interactive message reference number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
