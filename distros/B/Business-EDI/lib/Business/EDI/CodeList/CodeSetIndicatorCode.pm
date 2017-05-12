package Business::EDI::CodeList::CodeSetIndicatorCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9161;}
my $usage       = 'B';

# 9161  Code set indicator code                                 [B]
# Desc: Code indicating whether a data element has an
# associated code set.
# Repr: an..3

my %code_hash = (
'1' => [ 'Associated code set',
    'Data element has an associated code set.' ],
'2' => [ 'No associated code set',
    'Data element does not have an associated code set.' ],
);
sub get_codes { return \%code_hash; }

1;
