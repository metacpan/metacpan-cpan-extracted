package Business::EDI::CodeList::EmploymentDetailsCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9003;}
my $usage       = 'B';

# 9003  Employment details code qualifier                       [B]
# Desc: Code qualifying the employment details.
# Repr: an..3

my %code_hash = (
'1' => [ 'Primary',
    'Main employment.' ],
'2' => [ 'Secondary',
    'Secondary employment.' ],
'3' => [ 'Tertiary',
    'Tertiary employment.' ],
'4' => [ 'Profession',
    'To specify a profession.' ],
);
sub get_codes { return \%code_hash; }

1;
