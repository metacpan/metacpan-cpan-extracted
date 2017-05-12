package Business::EDI::CodeList::LengthTypeCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9155;}
my $usage       = 'B';

# 9155  Length type code                                        [B]
# Desc: Code specifying the type of length.
# Repr: an..3

my %code_hash = (
'1' => [ 'Fixed',
    'Length of simple data element is fixed.' ],
'2' => [ 'Variable',
    'Length of simple data element is variable.' ],
);
sub get_codes { return \%code_hash; }

1;
