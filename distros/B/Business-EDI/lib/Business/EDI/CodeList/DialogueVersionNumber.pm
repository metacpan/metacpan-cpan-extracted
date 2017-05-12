package Business::EDI::CodeList::DialogueVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0342";}
my $usage       = 'B';  # guessed value

# 0342 Dialogue version number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
