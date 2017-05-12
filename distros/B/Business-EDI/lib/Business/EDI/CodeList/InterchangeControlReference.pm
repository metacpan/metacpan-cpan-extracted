package Business::EDI::CodeList::InterchangeControlReference;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0020";}
my $usage       = 'B';  # guessed value

# 0020 Interchange control reference                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
