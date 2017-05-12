package Business::EDI::CodeList::MessageSubsetIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0115";}
my $usage       = 'B';  # guessed value

# 0115 Message subset identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
