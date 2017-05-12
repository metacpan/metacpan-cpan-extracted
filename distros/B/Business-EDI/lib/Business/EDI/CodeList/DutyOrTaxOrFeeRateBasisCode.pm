package Business::EDI::CodeList::DutyOrTaxOrFeeRateBasisCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5273;}
my $usage       = 'B';

# 5273  Duty or tax or fee rate basis code                      [B]
# Desc: Code specifying the basis for a duty or tax or fee
# rate.
# Repr: an..12

my %code_hash = (
'1' => [ 'Value',
    '(5316) To specify that the applicable rate of duty, tax or fee is based on the Customs value (CCC).' ],
'2' => [ 'Weight',
    'To specify that the applicable rate of duty, tax or fee is based on the weight of the item (CCC).' ],
'3' => [ 'Quantity',
    '(6060) To specify that the applicable rate of duty, tax or fee is based on the quantity of the item (CCC).' ],
);
sub get_codes { return \%code_hash; }

1;
