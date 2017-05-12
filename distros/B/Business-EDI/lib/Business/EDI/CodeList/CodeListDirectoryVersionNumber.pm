package Business::EDI::CodeList::CodeListDirectoryVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0110";}
my $usage       = 'B';  # guessed value

# 0110 Code list directory version number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
