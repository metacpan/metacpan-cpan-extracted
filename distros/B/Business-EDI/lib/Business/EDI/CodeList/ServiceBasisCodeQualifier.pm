package Business::EDI::CodeList::ServiceBasisCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9641;}
my $usage       = 'I';

# 9641  Service basis code qualifier                            [I]
# Desc: Code qualifying the basis on which a service is
# performed.
# Repr: an..3

my %code_hash = (
'1' => [ 'Condition',
    'The service was performed based on a condition.' ],
'2' => [ 'Occurrence',
    'The service was performed based on an occurrence.' ],
'3' => [ 'Occurrence span',
    'The service was performed based on an event occurring over a period of time.' ],
'4' => [ 'Procedure',
    'The service was performed based on a procedure.' ],
'5' => [ 'Value code',
    'The service was performed based on a value code.' ],
);
sub get_codes { return \%code_hash; }

1;
