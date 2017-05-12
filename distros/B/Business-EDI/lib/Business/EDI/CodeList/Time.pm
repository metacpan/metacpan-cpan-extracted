package Business::EDI::CodeList::Time;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0019";}
my $usage       = 'B';  # guessed value

# 0019 Time                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
