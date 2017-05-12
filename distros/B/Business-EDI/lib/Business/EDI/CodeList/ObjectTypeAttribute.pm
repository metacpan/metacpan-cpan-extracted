package Business::EDI::CodeList::ObjectTypeAttribute;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0808";}
my $usage       = 'B';  # guessed value

# 0808 Object type attribute                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
