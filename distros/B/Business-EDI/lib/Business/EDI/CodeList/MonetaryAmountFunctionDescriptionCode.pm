package Business::EDI::CodeList::MonetaryAmountFunctionDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5007;}
my $usage       = 'B';

# 5007  Monetary amount function description code               [B]
# Desc: Code specifying the monetary amount function.
# Repr: an..3

my %code_hash = (
'1' => [ 'Destination charge totals',
    'Code to indicate total charges levied at destination.' ],
'2' => [ 'Alternative currency amount',
    'The amount is expressed in alternate currency.' ],
'3' => [ 'Total message amount',
    'The total amount of the message.' ],
'4' => [ 'Invoices total amount summary',
    "The summary of a number of invoices' total amounts." ],
'5' => [ 'Amount for Customs purposes',
    'Number of monetary units expressed in a specified currency for Customs purposes (see: 5004).' ],
'7' => [ 'Financial transaction amount',
    'Amount refers to financial transaction.' ],
'8' => [ 'Total(s) of deferred items',
    'To specify the total(s) of all deferred items from one reinsurance account.' ],
'9' => [ 'Total(s) of open cash claims',
    'To specify the total(s) of all open cash claims from one reinsurance account.' ],
'10' => [ 'Reinsurance account balance',
    'To specify the result(s) of the reinsurance account calculation.' ],
'11' => [ 'Prepaid totals',
    'Totals of prepaid freight and charges.' ],
'12' => [ 'Collect totals',
    'Totals of collect freight and charges.' ],
'14' => [ 'Valuation amounts',
    'Code to indicate valuation amounts.' ],
'15' => [ 'Prepayment amount',
    'The amount paid or to be paid before a business transaction occurs.' ],
'16' => [ 'Alternative currency total amount',
    'The total amount expressed in an alternate currency.' ],
'17' => [ 'Documentary credit amount',
    'Value expressed in monetary terms of the documentary credit.' ],
'18' => [ 'Additional amounts covered: freight costs',
    'Freight costs are also covered under the documentary credit.' ],
'19' => [ 'Additional amounts covered: insurance costs',
    'Insurance costs are also covered under the documentary credit.' ],
'20' => [ 'Additional amounts covered: interest',
    'Interest on delayed or deferred payment is also covered under the documentary credit.' ],
'21' => [ 'Additional amounts covered: inspection costs',
    'Goods inspection costs are also covered under the documentary credit.' ],
'22' => [ 'Part of documentary credit amount',
    'Part of documentary credit subject to sight, deferred or acceptance payment when the documentary credit is available by mixed payment.' ],
'23' => [ 'Amount of note',
    'Amount of debit or credit note.' ],
'24' => [ 'Hash total',
    'Total sum of amounts specified for control purposes.' ],
'25' => [ 'Cumulative total, this period',
    'Totals to date.' ],
'26' => [ 'Period total',
    'Totals this measurement period.' ],
'27' => [ 'Cumulative total, preceding period',
    'Total to the end of last measurement period.' ],
'28' => [ 'Total balance credit risk covered',
    'The total balance of factored invoices which are covered for credit risk.' ],
'29' => [ 'Labour costs',
    'Identifying costs related to labour resource.' ],
'30' => [ 'Business credit amount',
    'Monetary amount(s) associated with business credit information.' ],
);
sub get_codes { return \%code_hash; }

1;
