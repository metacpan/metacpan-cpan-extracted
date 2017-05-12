package Business::EDI::CodeList::PayerResponsibilityLevelCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9645;}
my $usage       = 'I';

# 9645  Payer responsibility level code                         [I]
# Desc: Code specifying the level of responsibility of a
# payer.
# Repr: an..3

my %code_hash = (
'1' => [ 'Primary',
    'First for payment responsibility.' ],
'2' => [ 'Secondary',
    'Second for payment responsibility.' ],
'3' => [ 'Tertiary',
    'Third for payment responsibility.' ],
'4' => [ 'Unconfirmed',
    'Payment responsibility is yet to be determined.' ],
'5' => [ 'None',
    'No payment responsibility.' ],
'6' => [ 'Unknown',
    'Unknown payment responsibility.' ],
);
sub get_codes { return \%code_hash; }

1;
