package Business::EDI::CodeList::MaintenanceOperationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4513;}
my $usage       = 'C';

# 4513  Maintenance operation code                              [C]
# Desc: Code specifying a maintenance operation.
# Repr: an..3

my %code_hash = (
'1' => [ 'New',
    'The data is to be processed as new.' ],
'2' => [ 'Add and replace',
    'The data contains new objects, which are to be added, and existing objects, which are to replace objects which have the same identifier.' ],
'3' => [ 'Replace',
    'The data is to replace existing data which has the same identifier.' ],
'4' => [ 'Delete',
    'The data identified is to be deleted.' ],
'5' => [ 'None',
    'The data is not to be maintained.' ],
'6' => [ 'Addition',
    'Maintenance operation involves addition.' ],
'7' => [ 'Change',
    'Maintenance operation involves change.' ],
'8' => [ 'Marked for deletion',
    'The item is marked for deletion in a future release.' ],
'9' => [ 'Repair',
    'Maintenance operation involves repair.' ],
'10' => [ 'Cleaning',
    'Maintenance operation involves cleaning.' ],
'11' => [ 'Waste disposal',
    'Maintenance operation involves waste disposal.' ],
'12' => [ 'Return of empty packages',
    'Maintenance operation involves return of empty packages.' ],
);
sub get_codes { return \%code_hash; }

1;
