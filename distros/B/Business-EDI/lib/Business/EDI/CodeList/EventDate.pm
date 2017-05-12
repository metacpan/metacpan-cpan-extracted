package Business::EDI::CodeList::EventDate;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0338";}
my $usage       = 'B';  # guessed value

# 0338 Event date                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
