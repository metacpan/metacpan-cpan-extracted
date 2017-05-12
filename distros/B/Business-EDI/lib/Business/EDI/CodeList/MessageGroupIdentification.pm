package Business::EDI::CodeList::MessageGroupIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0038";}
my $usage       = 'B';  # guessed value

# 0038 Message group identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
