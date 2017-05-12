package Business::EDI::CodeList::ApplicationPassword;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0058";}
my $usage       = 'B';  # guessed value

# 0058 Application password                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
