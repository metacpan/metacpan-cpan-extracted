package Business::EDI::CodeList::TransactionControlReference;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0306";}
my $usage       = 'B';  # guessed value

# 0306 Transaction control reference                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
