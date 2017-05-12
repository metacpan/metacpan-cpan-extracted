package Business::EDI::CodeList::MessageReferenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0062";}
my $usage       = 'B';  # guessed value

# 0062 Message reference number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
