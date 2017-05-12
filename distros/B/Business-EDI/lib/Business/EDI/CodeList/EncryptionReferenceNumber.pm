package Business::EDI::CodeList::EncryptionReferenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0518";}
my $usage       = 'B';  # guessed value

# 0518 Encryption reference number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
