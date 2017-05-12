package Business::EDI::CodeList::DutyOrTaxOrFeeFunctionCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5283;}
my $usage       = 'B';

# 5283  Duty or tax or fee function code qualifier              [B]
# Desc: Code qualifying the function of a duty or tax or fee.
# Repr: an..3

my %code_hash = (
'1' => [ 'Individual duty, tax or fee (Customs item)',
    'Individual duty, tax or fee charged on a single Customs item line of the goods declaration (CCC).' ],
'2' => [ 'Total of all duties, taxes and fees (Customs item)',
    'Total of all duties, taxes and fees charged on a single Customs item line of the goods declaration (CCC).' ],
'3' => [ 'Total of each duty, tax or fee type (Customs declaration)',
    'Total of each duty, tax or fee charged on the goods declaration (CCC).' ],
'4' => [ 'Total of all duties, taxes and fee types (Customs',
    'declaration) Total of all duties, taxes and fees charged on the goods declaration (CCC).' ],
'5' => [ 'Customs duty',
    'Duties laid down in the Customs tariff to which goods are liable on entering or leaving the Customs territory (CCC).' ],
'6' => [ 'Fee',
    'Charge for services rendered.' ],
'7' => [ 'Tax',
    'Contribution levied by an authority.' ],
'9' => [ 'Tax related information',
    'Code specifying information related to tax.' ],
);
sub get_codes { return \%code_hash; }

1;
