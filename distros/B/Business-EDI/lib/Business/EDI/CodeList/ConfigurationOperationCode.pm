package Business::EDI::CodeList::ConfigurationOperationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7083;}
my $usage       = 'B';

# 7083  Configuration operation code                            [B]
# Desc: Code specifying the configuration operation.
# Repr: an..3

my %code_hash = (
'A' => [ 'Added to the configuration',
    'The operation is to add to the configuration.' ],
'D' => [ 'Deleted from the configuration',
    'The operation is to delete from the configuration.' ],
'I' => [ 'Included in the configuration',
    'The item is a part of the configuration.' ],
);
sub get_codes { return \%code_hash; }

1;
