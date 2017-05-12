package Business::EDI::CodeList::Status;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0332";}
my $usage       = 'B';  # guessed value

# 0332 Status                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
