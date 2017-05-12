package Business::EDI::CodeList::AccountTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4437;}
my $usage       = 'B';

# 4437  Account type code qualifier                             [B]
# Desc: Code qualifying the type of account.
# Repr: an..3

my %code_hash = (
'1' => [ 'Cost account',
    'Code identifying a cost account.' ],
'2' => [ 'Budgetary account',
    'Code identifying a budgetary account.' ],
'3' => [ 'Subsidiary account',
    'Code identifying a subsidiary account.' ],
'4' => [ 'General account',
    'Code identifying a general account.' ],
'5' => [ 'Related account',
    'Account that is related to an other account.' ],
'6' => [ 'General trial balance',
    'Code identifying a general trial balance.' ],
'7' => [ 'Subsidiary trial balance',
    'Code identifying a subsidiary trial balance.' ],
'8' => [ 'Cost trial balance',
    'Code identifying a cost trial balance.' ],
'9' => [ 'Budgetary trial balance',
    'Code identifying a budgetary trial balance.' ],
'10' => [ 'General and cost trial balance',
    'Code identifying a general and cost trial balance.' ],
'11' => [ 'General and budgetary trial balance',
    'Code identifying a general and budgetary trial balance.' ],
'12' => [ 'General and subsidiary trial balance',
    'Code identifying a general and subsidiary trial balance.' ],
'13' => [ 'Cost and budgetary trial balance',
    'Code identifying a cost and budgetary trial balance.' ],
'14' => [ 'Cost and subsidiary trial balance',
    'Code identifying a cost and subsidiary trial balance.' ],
'15' => [ 'Budgetary and subsidiary trial balance',
    'Code identifying a budgetary and subsidiary trial balance.' ],
'16' => [ 'General, cost and budgetary trial balance',
    'Code identifying a general, cost and budgetary trial balance.' ],
'17' => [ 'Non recorded differences account',
    'Code identifying the account of non recorded differences.' ],
);
sub get_codes { return \%code_hash; }

1;
