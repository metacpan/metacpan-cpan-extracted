package Business::EDI::CodeList::EventTime;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0314";}
my $usage       = 'B';  # guessed value

# 0314 Event time                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
