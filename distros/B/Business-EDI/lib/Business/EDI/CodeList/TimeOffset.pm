package Business::EDI::CodeList::TimeOffset;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0336";}
my $usage       = 'B';  # guessed value

# 0336 Time offset                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
