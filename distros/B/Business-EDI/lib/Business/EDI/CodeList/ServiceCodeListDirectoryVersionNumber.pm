package Business::EDI::CodeList::ServiceCodeListDirectoryVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0080";}
my $usage       = 'B';  # guessed value

# 0080 Service code list directory version number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
