package Business::EDI::CodeList::InterchangeControlCount;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0036";}
my $usage       = 'B';  # guessed value

# 0036 Interchange control count                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
