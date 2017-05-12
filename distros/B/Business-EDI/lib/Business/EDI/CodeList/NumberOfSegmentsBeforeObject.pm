package Business::EDI::CodeList::NumberOfSegmentsBeforeObject;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0814";}
my $usage       = 'B';  # guessed value

# 0814 Number of segments before object                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
