package Business::EDI::CodeList::KeyName;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0538";}
my $usage       = 'B';  # guessed value

# 0538 Key name                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
