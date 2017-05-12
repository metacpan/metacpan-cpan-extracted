package Business::EDI::CodeList::InformationDetailsCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9633;}
my $usage       = 'B';

# 9633  Information details code qualifier                      [B]
# Desc: Code qualifying the information details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Business information',
    'Identifies information related to the business.' ],
);
sub get_codes { return \%code_hash; }

1;
