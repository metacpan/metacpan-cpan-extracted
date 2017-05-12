package Business::EDI::CodeList::ApplicabilityCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9051;}
my $usage       = 'B';

# 9051  Applicability code qualifier                            [B]
# Desc: Code qualifying the applicability.
# Repr: an..3

my %code_hash = (
'1' => [ 'Basis',
    'Foundation or starting point.' ],
);
sub get_codes { return \%code_hash; }

1;
