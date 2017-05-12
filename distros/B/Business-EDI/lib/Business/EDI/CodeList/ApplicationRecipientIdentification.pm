package Business::EDI::CodeList::ApplicationRecipientIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0044";}
my $usage       = 'B';  # guessed value

# 0044 Application recipient identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
