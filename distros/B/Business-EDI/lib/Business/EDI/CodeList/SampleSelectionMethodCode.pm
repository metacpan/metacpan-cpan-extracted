package Business::EDI::CodeList::SampleSelectionMethodCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7039;}
my $usage       = 'B';

# 7039  Sample selection method code                            [B]
# Desc: Code specifying the selection method for a sample.
# Repr: an..3

my %code_hash = (
'1' => [ 'Random selection',
    'The selection method is helter-skelter.' ],
'2' => [ 'Sequential specimen',
    'Selection method is in consecutive order.' ],
);
sub get_codes { return \%code_hash; }

1;
