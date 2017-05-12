package Business::EDI::CodeList::ModeOfOperationCodeListIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0533";}
my $usage       = 'B';

# 0533  Mode of operation code list identifier
# Desc: Specification of the code list used to identify the
# cryptographic mode of operation.
# Repr: an..3

my %code_hash = (
'1' => [ 'UN/CEFACT',
    'United Nations Centre for Trade Facilitation and Electronic Business (UN/CEFACT).' ],
);
sub get_codes { return \%code_hash; }

1;
