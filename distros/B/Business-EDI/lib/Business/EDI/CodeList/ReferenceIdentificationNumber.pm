package Business::EDI::CodeList::ReferenceIdentificationNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0802";}
my $usage       = 'B';  # guessed value

# 0802 Reference identification number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
