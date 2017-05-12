package Business::EDI::CodeList::NumberOfPaddingBytes;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0582";}
my $usage       = 'B';  # guessed value

# 0582 Number of padding bytes                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
