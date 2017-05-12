package Business::EDI::CodeList::SealTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4525;}
my $usage       = 'B';

# 4525  Seal type code                                          [B]
# Desc: To specify a type of seal.
# Repr: an..3

my %code_hash = (
'1' => [ 'Mechanical seal',
    'The seal is mechanical.' ],
'2' => [ 'Electronic seal',
    'The seal is electronic.' ],
);
sub get_codes { return \%code_hash; }

1;
