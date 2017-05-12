package Business::EDI::CodeList::NumberOfSegmentsInAMessage;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0074";}
my $usage       = 'B';  # guessed value

# 0074 Number of segments in a message                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
