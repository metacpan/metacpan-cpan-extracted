package Business::EDI::CodeList::IndexCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {5013;}
my $usage       = 'B';

# 5013  Index code qualifier                                    [B]
# Desc: Code qualifying an index.
# Repr: an..3

my %code_hash = (
'1' => [ 'Project',
    'Indicates that the index relates to the whole project.' ],
'2' => [ 'Group',
    'Indicates that the index relates to a group of work items.' ],
'3' => [ 'Alternative',
    'Indicates that the index is an alternative.' ],
);
sub get_codes { return \%code_hash; }

1;
