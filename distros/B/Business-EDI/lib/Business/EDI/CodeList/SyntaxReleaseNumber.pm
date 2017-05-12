package Business::EDI::CodeList::SyntaxReleaseNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0076";}
my $usage       = 'B';  # guessed value

# 0076 Syntax release number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
