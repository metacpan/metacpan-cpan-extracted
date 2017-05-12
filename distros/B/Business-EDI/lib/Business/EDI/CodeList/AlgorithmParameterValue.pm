package Business::EDI::CodeList::AlgorithmParameterValue;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0554";}
my $usage       = 'B';  # guessed value

# 0554 Algorithm parameter value                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
