package Business::EDI::CodeList::FinancialTransactionTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4487;}
my $usage       = 'B';

# 4487  Financial transaction type code                         [B]
# Desc: Code specifying a type of financial transaction.
# Repr: an..3

my %code_hash = (
'1' => [ 'Clean payment',
    'Payment under open account terms.' ],
'2' => [ 'Pre-authorised direct debit or direct debit request',
    'The transaction is a pre-authorised direct debit or direct debit request, i.e. a direct debit for which there is an agreed mandate that allows the creditor to draw funds from the debtor.' ],
'3' => [ 'Non pre-authorised direct debit or direct debit request',
    'The transaction is a non pre-authorised direct debit or direct debit request, i.e. a direct debit for which there is no prior agreed mandate allowing the creditor to draw funds from the debtor.' ],
'4' => [ 'Documentary payment',
    'Payment relating to a documentary settlement.' ],
'5' => [ 'Irrevocable documentary credit',
    'The documentary credit is irrevocable.' ],
'6' => [ 'Revocable documentary credit',
    'The documentary credit is revocable.' ],
'7' => [ 'Irrevocable and transferable documentary credit',
    'The documentary credit is irrevocable and may be transferred to a second beneficiary.' ],
'8' => [ 'Revocable and transferable documentary credit',
    'The documentary credit is revocable and may be transferred to a second beneficiary.' ],
'9' => [ 'Revocable and transferable standby letter of credit',
    'Revocable and transferable standby letter of credit.' ],
'10' => [ 'Irrevocable and transferable standby letter of credit',
    'Irrevocable and transferable standby letter of credit.' ],
'11' => [ 'Revocable standby letter of credit',
    'Revocable standby letter of credit.' ],
'12' => [ 'Irrevocable standby letter of credit',
    'Irrevocable standby letter of credit.' ],
'13' => [ 'Pre-advised direct debit',
    'The transaction is a direct debit about which the debtor has advised his bank prior to the creditor raising the direct debit, giving his bank permission to debit his account.' ],
'14' => [ 'Non pre-advised direct debit',
    'The transaction is a direct debit about which the debtor has not advised his bank prior to the creditor raising the direct debit.' ],
'15' => [ 'Irrevocable reimbursement of cash withdrawal',
    'The transaction is an irrevocable direct debit, from bank A to bank B, which reimburses bank A that has by agreement provided cash to a customer of bank B.' ],
);
sub get_codes { return \%code_hash; }

1;
