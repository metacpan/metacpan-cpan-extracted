package Business::EDI::CodeList::SequenceOfTransfers;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0070";}
my $usage       = 'B';  # guessed value

# 0070 Sequence of transfers                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
