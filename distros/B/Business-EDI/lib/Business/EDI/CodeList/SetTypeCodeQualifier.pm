package Business::EDI::CodeList::SetTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7297;}
my $usage       = 'B';

# 7297  Set type code qualifier                                 [B]
# Desc: Code qualifying the type of set.
# Repr: an..3

my %code_hash = (
'1' => [ 'Product',
    'Identification of the product set.' ],
'2' => [ 'Licence',
    'Identification of the licence set.' ],
'3' => [ 'Package',
    'Related numbers identifying a package such as a bar code label number related to a kanban card number, etc.' ],
'4' => [ 'Vehicle reference set',
    'A code which indicates that the identities which follow are related to a particular vehicle which may have been previously identified.' ],
'5' => [ 'Source database',
    'The source database of the data in a data set.' ],
'6' => [ 'Target database',
    'The target database for the data in a data set.' ],
'7' => [ 'Value list',
    'A coded or non coded list of values.' ],
'8' => [ 'Contract',
    'The contract related item numbers.' ],
'9' => [ 'Financial security',
    'Financial security identifier set.' ],
'10' => [ 'Accounting',
    'A code to identify a set of numbers used for accounting.' ],
'11' => [ 'Project',
    'A set of numbers to identify a project.' ],
'12' => [ 'Work plan',
    'A set of numbers to identify a plan of work.' ],
'13' => [ 'Work schedule',
    'A set of numbers to identify a schedule of work.' ],
'14' => [ 'Resource',
    'A set of numbers to identify a resource.' ],
'15' => [ 'Milestone event',
    'A set of numbers to identify a milestone event.' ],
'16' => [ 'Interface work task',
    'A set of numbers to identify an interface work task.' ],
'17' => [ 'Work task constraint',
    'A set of numbers to identify a work task constraint.' ],
'18' => [ 'Data structure position number',
    "Position number(s) of a data structure's relevant components." ],
);
sub get_codes { return \%code_hash; }

1;
