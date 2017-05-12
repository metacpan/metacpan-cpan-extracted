package Business::EDI::CodeList::GovernmentInvolvementCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9411;}
my $usage       = 'B';

# 9411  Government involvement code                             [B]
# Desc: Code indicating the requirement and status of
# governmental involvement.
# Repr: an..3

my %code_hash = (
'1' => [ 'Carried out as instructed',
    'Instructions have been carried out.' ],
'2' => [ 'Carried out as amended',
    'Procedures have been carried out as amended.' ],
'3' => [ 'Completed',
    'Procedures have been completed.' ],
'4' => [ 'Not applicable',
    'Instructions are not applicable.' ],
'5' => [ 'Optimal',
    'An action which is most desirable but not required.' ],
'6' => [ 'Required',
    'Procedures are required.' ],
'7' => [ 'Applicable',
    'Procedures are applicable.' ],
'8' => [ 'Export certificate required',
    'Indication by exporter that they need certificate of export from Customs.' ],
);
sub get_codes { return \%code_hash; }

1;
