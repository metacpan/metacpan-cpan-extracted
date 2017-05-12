package Business::EDI::CodeList::CertificateSequenceNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0572";}
my $usage       = 'B';  # guessed value

# 0572 Certificate sequence number                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
