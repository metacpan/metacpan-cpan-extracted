package Business::EDI::CodeList::ProcessStageCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9421;}
my $usage       = 'B';

# 9421  Process stage code qualifier                            [B]
# Desc: Code qualifying a stage in a process.
# Repr: an..3

my %code_hash = (
'1' => [ 'Amortization',
    'Amortization of tooling costs.' ],
);
sub get_codes { return \%code_hash; }

1;
