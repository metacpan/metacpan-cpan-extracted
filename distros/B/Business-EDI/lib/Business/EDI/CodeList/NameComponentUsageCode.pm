package Business::EDI::CodeList::NameComponentUsageCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3401;}
my $usage       = 'B';

# 3401  Name component usage code                               [B]
# Desc: Code specifying the usage of a name component.
# Repr: an..3

my %code_hash = (
'2' => [ 'Used name component',
    'Part of the name usually used.' ],
'3' => [ 'Abbreviated name',
    'The name is an abbreviation of the official name.' ],
);
sub get_codes { return \%code_hash; }

1;
