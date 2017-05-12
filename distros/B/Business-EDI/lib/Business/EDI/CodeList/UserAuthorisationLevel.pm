package Business::EDI::CodeList::UserAuthorisationLevel;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0546";}
my $usage       = 'B';  # guessed value

# 0546 User authorisation level                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
