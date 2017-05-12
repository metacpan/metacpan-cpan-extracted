package Business::EDI::CodeList::StatusCategoryCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9015;}
my $usage       = 'B';

# 9015  Status category code                                    [B]
# Desc: Code specifying the category of a status.
# Repr: an..3

my %code_hash = (
'1' => [ 'Transport',
    'Status type is related to transport.' ],
'2' => [ 'Order administration',
    'Status type is related to order administration.' ],
'3' => [ 'Inspection result',
    'To specify the result of an inspection.' ],
'4' => [ 'Publication issue claim',
    'The status reported is related to a publication issue claim.' ],
'5' => [ 'Legal category',
    'Status category is of, related to or concerned with the law.' ],
'6' => [ 'Contract',
    'The status reported is related to a contract.' ],
'7' => [ 'Transaction',
    'The status reported is related to a transaction.' ],
'8' => [ 'Meter reading quality',
    'The quality of a meter reading.' ],
'9' => [ 'Capacity',
    'The status reported is related to a capacity.' ],
'10' => [ 'Measurement classification',
    'The status is related to the categorization of measurement.' ],
'11' => [ 'Transport means security status',
    'A code describing the security status of a means of transport including security certification status of the transport means and status of maintained or required security procedures during transport operations.' ],
);
sub get_codes { return \%code_hash; }

1;
