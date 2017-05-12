package Business::EDI::CodeList::MessageSubsetVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0116";}
my $usage       = 'B';  # guessed value

# 0116 Message subset version number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
