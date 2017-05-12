package Business::EDI::CodeList::SupportingEvidenceTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9643;}
my $usage       = 'I';

# 9643  Supporting evidence type code qualifier                 [I]
# Desc: Code qualifying the type of supporting evidence.
# Repr: an..3

my %code_hash = (
'1' => [ 'Radiology film',
    'X-ray image.' ],
);
sub get_codes { return \%code_hash; }

1;
