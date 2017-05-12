package Business::EDI::CodeList::ClauseCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4059;}
my $usage       = 'B';

# 4059  Clause code qualifier                                   [B]
# Desc: Code qualifying the nature of the clause.
# Repr: an..3

my %code_hash = (
'1' => [ 'Insurance policy',
    'Clause relating to an insurance policy.' ],
);
sub get_codes { return \%code_hash; }

1;
