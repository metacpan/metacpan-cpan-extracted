package Business::EDI::CodeList::ApplicationReference;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0026";}
my $usage       = 'B';  # guessed value

# 0026 Application reference                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
