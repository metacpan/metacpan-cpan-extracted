package Business::EDI::CodeList::AllowanceOrChargeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5463;}
my $usage       = 'B';

# 5463  Allowance or charge code qualifier                      [B]
# Desc: Code qualifying an allowance or charge.
# Repr: an..3

my %code_hash = (
'A' => [ 'Allowance',
    'Code specifying an allowance.' ],
'B' => [ 'Total other',
    'The total for items other than those primarily reported upon in the message.' ],
'C' => [ 'Charge',
    'Code specifying a charge.' ],
'D' => [ 'Allowance per call off',
    'Code specifying a call off allowance.' ],
'E' => [ 'Charge per call off',
    'Code specifying a charge per call off.' ],
'F' => [ 'Allowance message',
    'Allowance is related to the entire message.' ],
'G' => [ 'Allowance line items',
    'Allowance is related to all line items in a message as a default allowance. It may be overridden per line item.' ],
'H' => [ 'Line item allowance',
    'Allowance is related to a line item. It can override a default allowance.' ],
'J' => [ 'Adjustment',
    'Code specifying that the allowance or charge is due to an adjustment.' ],
'K' => [ 'Charge message',
    'Charge is related to the entire message.' ],
'L' => [ 'Charge line items',
    'Charge is related to all line items in a message as a default charge. It may be overridden per line item.' ],
'M' => [ 'Line item charge',
    'Charge is related to a line item. It can override a default charge.' ],
'N' => [ 'No allowance or charge',
    'No increases or reduction in price (list or stated) are included.' ],
'O' => [ 'About',
    'To be construed as allowing a difference not exceeding 10 % more or 10 % less than the amount which it refers.' ],
'P' => [ 'Minus (percentage)',
    'The lesser value expressed in percentage.' ],
'Q' => [ 'Minus (amount)',
    'The lesser value expressed in amount.' ],
'R' => [ 'Plus (percentage)',
    'The greater value expressed in percentage.' ],
'S' => [ 'Plus (amount)',
    'The greater value expressed in amount.' ],
'T' => [ 'Plus/minus (percentage)',
    'The greater/lesser value expressed in percentage.' ],
'U' => [ 'Plus/minus (amount)',
    'The greater/lesser value expressed in amount.' ],
'V' => [ 'No allowance',
    'Code specifying that there is no allowance.' ],
'W' => [ 'No charge',
    'Code specifying that there is no charge.' ],
'X' => [ 'Maximum',
    'Highest possible value; maximum; not exceeding; up to.' ],
'Y' => [ 'Exact',
    'Indicates that this is the exact amount.' ],
);
sub get_codes { return \%code_hash; }

1;
