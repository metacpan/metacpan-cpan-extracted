package Business::EDI::CodeList::ResultValueTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6087;}
my $usage       = 'B';

# 6087  Result value type code qualifier                        [B]
# Desc: Code qualifying the type of a result value.
# Repr: an..3

my %code_hash = (
'1' => [ 'Measurement result',
    'Measurement result.' ],
'2' => [ 'Bank accounts history assessment',
    'The conclusion resulting from an assessment of bank accounts over time.' ],
'3' => [ 'Credit level',
    'The resultant assignment of a credit level based on an assessment of credit worthiness.' ],
'4' => [ 'Credit rating assessment',
    'The resultant assignment of a credit rating based on an assessment of credit worthiness.' ],
'5' => [ 'Credit worthiness assessment',
    'The resulting assessment of credit worthiness.' ],
'6' => [ 'Liquidity assessment',
    'The resulting assessment of liquidity.' ],
'7' => [ 'Loan payment history',
    'The resulting assessment of loan payment history.' ],
'8' => [ 'Overall evaluation',
    'The summarization of the overall assessment.' ],
'9' => [ 'Financial conditions',
    'The resulting assessment of financial conditions.' ],
'10' => [ 'Trade payments',
    'The resulting assessment of trade payments.' ],
'11' => [ 'Failure risk score ranking',
    "The resulting ranking based on one entity's failure risk score as compared to other entities." ],
'12' => [ 'Failure risk score',
    'Score representing the risk of an entity failing.' ],
'13' => [ 'Business financing resources assessment',
    'The resulting assessment of resources used for financing a business.' ],
'14' => [ 'Payment delinquency risk score',
    'The resulting assessment of the risk of an entity having delinquent payments.' ],
'15' => [ 'Payment delinquency performance score',
    "The resulting assessment of the entity's actual delinquent payments." ],
'16' => [ 'Payment delinquency score ranking',
    "The resulting ranking of one entity's payment delinquency score as compared to other entities." ],
'17' => [ 'Payment delinquency assessment',
    'The resulting assessment of delinquencies as they relate to all entities.' ],
'18' => [ 'Average trade payment for all entities',
    'The assessment of average trade payments for all entities.' ],
'19' => [ 'Revenue ranking',
    'The resulting ranking based on revenue.' ],
'20' => [ 'Sales growth ranking',
    'The resulting ranking based on sales growth.' ],
'21' => [ 'Asset ranking',
    'The resulting ranking based on assets.' ],
'22' => [ 'Profit margin ranking',
    'The resulting ranking based on profit margin.' ],
'23' => [ 'Post tax profit ranking',
    'The resulting ranking based on after taxes profit.' ],
'24' => [ 'Import and export ranking',
    'The resulting ranking based on imports and exports.' ],
'25' => [ 'Projected trade payments',
    'The resulting assessment of projected trade payments.' ],
'26' => [ 'Invoice collection',
    'The resulting assessment based on the collection of invoices.' ],
);
sub get_codes { return \%code_hash; }

1;
