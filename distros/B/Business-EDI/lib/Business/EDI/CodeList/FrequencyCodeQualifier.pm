package Business::EDI::CodeList::FrequencyCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6071;}
my $usage       = 'B';

# 6071  Frequency code qualifier                                [B]
# Desc: Code qualifying the frequency.
# Repr: an..3

my %code_hash = (
'1' => [ 'Sample frequency',
    'The rate at which goods are sampled over a particular period.' ],
);
sub get_codes { return \%code_hash; }

1;
