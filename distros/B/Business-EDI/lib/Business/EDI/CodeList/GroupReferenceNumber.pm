package Business::EDI::CodeList::GroupReferenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0048";}
my $usage       = 'B';  # guessed value

# 0048 Group reference number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
