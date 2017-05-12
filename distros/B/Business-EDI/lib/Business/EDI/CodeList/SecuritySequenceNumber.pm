package Business::EDI::CodeList::SecuritySequenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0520";}
my $usage       = 'B';  # guessed value

# 0520 Security sequence number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
