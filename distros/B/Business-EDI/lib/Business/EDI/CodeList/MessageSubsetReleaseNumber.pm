package Business::EDI::CodeList::MessageSubsetReleaseNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0118";}
my $usage       = 'B';  # guessed value

# 0118 Message subset release number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
