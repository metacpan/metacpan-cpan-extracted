package Business::EDI::CodeList::GovernmentProcedureCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9353;}
my $usage       = 'B';

# 9353  Government procedure code                               [B]
# Desc: Code specifying a government procedure.
# Repr: an..3

my %code_hash = (
'1' => [ 'Already customs cleared in the importing country',
    'Arrangements for inspection are not necessary because they were cleared before.' ],
'2' => [ 'Documents requirements completed',
    'All requirements for documents have been completed.' ],
'3' => [ 'Documents required',
    'Pertinent documents are required.' ],
'4' => [ 'Inspection arrangements completed',
    'Arrangements for inspection of the cargo have been completed.' ],
'5' => [ 'Inspection arrangements required',
    'Arrangements for inspection of the cargo are required.' ],
'6' => [ 'No customs procedure',
    'Customs clearance not required.' ],
'7' => [ 'Safety arrangements completed',
    'Arrangements for safeguarding the cargo have been completed.' ],
'8' => [ 'Safety arrangements required',
    'Arrangements for safeguarding the cargo are required.' ],
'9' => [ 'Security arrangements required',
    'Arrangements for the security of the cargo are required.' ],
'10' => [ 'Storage arrangements completed',
    'Arrangements for storing the cargo have been completed.' ],
'11' => [ 'Storage arrangements required',
    'Arrangements for storing the cargo are required.' ],
'12' => [ 'Transport arrangements completed',
    'All arrangements for transport have been completed.' ],
'13' => [ 'Transport arrangements required',
    'Transport has to be arranged.' ],
);
sub get_codes { return \%code_hash; }

1;
