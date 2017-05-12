package Business::EDI::CodeList::ServiceCharacterForSignature;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0548";}
my $usage       = 'B';  # guessed value

# 0548 Service character for signature                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
