package Business::EDI::CodeList::DataElementUsageTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9175;}
my $usage       = 'B';

# 9175  Data element usage type code                            [B]
# Desc: Code specifying the usage type of a data element.
# Repr: an..3

my %code_hash = (
'1' => [ 'Component data element',
    'The associated data element is used within a composite.' ],
'2' => [ 'Simple data element',
    'The associated data element is used as a stand-alone element.' ],
'3' => [ 'Composite data element',
    'The associated data element is a composite data element.' ],
);
sub get_codes { return \%code_hash; }

1;
