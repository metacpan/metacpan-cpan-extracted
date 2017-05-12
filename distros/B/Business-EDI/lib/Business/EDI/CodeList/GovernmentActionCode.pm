package Business::EDI::CodeList::GovernmentActionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9417;}
my $usage       = 'B';

# 9417  Government action code                                  [B]
# Desc: Code specifying a type of government action such as
# inspection, detention, fumigation, security.
# Repr: an..3

my %code_hash = (
'1' => [ 'Clearance',
    'The cargo will be or has been cleared.' ],
'2' => [ 'Detention',
    'The cargo has been or will be detained.' ],
'3' => [ 'Fumigation',
    'The cargo has been or will be fumigated.' ],
'4' => [ 'Inspection',
    'The cargo has been or will be inspected.' ],
'5' => [ 'Security',
    'The cargo has been or will be secured.' ],
'6' => [ 'Means of transport admittance',
    'The means of transport will be or has been admitted.' ],
'7' => [ 'Cargo hold inspection',
    'The cargo hold has been or will be inspected.' ],
'8' => [ 'Container inspection',
    'The container has been or will be inspected.' ],
'9' => [ 'Cargo packaging inspection',
    'The cargo packaging has been or will be inspected.' ],
'10' => [ 'Export certificate not required',
    'Indication by exporter that they do not need certificate of export from Customs.' ],
);
sub get_codes { return \%code_hash; }

1;
