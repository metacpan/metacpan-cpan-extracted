package Business::EDI::CodeList::CreditCoverResponseReasonCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4509;}
my $usage       = 'B';

# 4509  Credit cover response reason code                       [B]
# Desc: Code specifying the reason for a response to a request
# for credit cover.
# Repr: an..3

my %code_hash = (
'1' => [ 'Requested financial information not provided',
    'Party requested has not provided financial information.' ],
'2' => [ 'No financial information available',
    'No financial information is available on buyer.' ],
'3' => [ 'Debtor is out of business',
    'Debtor ceased trading activities.' ],
'4' => [ 'Debtor is new company',
    'Debtor is newly incorporated.' ],
'5' => [ 'Debtor is not registered',
    'Debtor is not formally registered as legal entity.' ],
'6' => [ 'Debtor is non-trading company',
    'Debtor without trading, e.g. holding company.' ],
'7' => [ 'No comment',
    'No information can be disclosed.' ],
'8' => [ 'Only insolvency risk covered',
    'Only the risk of insolvency is covered.' ],
'9' => [ 'Subject to acceptance of bill of exchange',
    "Limit cover conditional to buyer's acceptance of bill of exchange." ],
'10' => [ 'Document against acceptance',
    'Limit given on documents against acceptance terms.' ],
'11' => [ 'Document against payment',
    'Limit given on documents against payment terms.' ],
'12' => [ 'Adverse information is publicly available',
    'Adverse information on buyer is publicly available.' ],
'13' => [ 'Credit limit full',
    'No approval or increase in credit possible.' ],
'14' => [ 'Lack of turnover',
    'Limit reduced. E.g. cancelled due to absence of activity.' ],
'15' => [ 'Other',
    'Reasons not otherwise specified here.' ],
);
sub get_codes { return \%code_hash; }

1;
