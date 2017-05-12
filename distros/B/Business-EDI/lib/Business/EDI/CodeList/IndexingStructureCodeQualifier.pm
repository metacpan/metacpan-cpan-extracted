package Business::EDI::CodeList::IndexingStructureCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7429;}
my $usage       = 'B';

# 7429  Indexing structure code qualifier                       [B]
# Desc: Code qualifying an indexing structure.
# Repr: an..3

my %code_hash = (
'1' => [ 'Project index',
    'Identifies the associated bill level identifiers as belonging to the project index.' ],
'2' => [ 'Alternative index',
    'Identifies the associated bill level identifiers as belonging to an alternative index.' ],
);
sub get_codes { return \%code_hash; }

1;
