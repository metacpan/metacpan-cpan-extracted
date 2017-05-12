package Business::EDI::CodeList::StatusCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0333";}
my $usage       = 'B';  # guessed value

# 0333 Status, coded                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
