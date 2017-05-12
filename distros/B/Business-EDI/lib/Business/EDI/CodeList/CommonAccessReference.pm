package Business::EDI::CodeList::CommonAccessReference;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0068";}
my $usage       = 'B';  # guessed value

# 0068 Common access reference                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
