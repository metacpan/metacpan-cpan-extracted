package Business::EDI::CodeList::ValidationValue;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0560";}
my $usage       = 'B';  # guessed value

# 0560 Validation value                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
