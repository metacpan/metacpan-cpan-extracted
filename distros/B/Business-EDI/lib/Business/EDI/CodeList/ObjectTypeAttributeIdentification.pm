package Business::EDI::CodeList::ObjectTypeAttributeIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0809";}
my $usage       = 'B';  # guessed value

# 0809 Object type attribute identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
