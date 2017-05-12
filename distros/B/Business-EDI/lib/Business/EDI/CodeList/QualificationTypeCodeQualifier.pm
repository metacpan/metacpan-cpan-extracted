package Business::EDI::CodeList::QualificationTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9037;}
my $usage       = 'B';

# 9037  Qualification type code qualifier                       [B]
# Desc: Code qualifying a type of qualification.
# Repr: an..3

my %code_hash = (
'1' => [ 'Formal professional qualification',
    'Formal professional qualification of person.' ],
);
sub get_codes { return \%code_hash; }

1;
