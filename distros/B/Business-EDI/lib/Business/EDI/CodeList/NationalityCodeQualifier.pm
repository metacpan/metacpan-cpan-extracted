package Business::EDI::CodeList::NationalityCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3493;}
my $usage       = 'B';

# 3493  Nationality code qualifier                              [B]
# Desc: Code qualifying a nationality.
# Repr: an..3

my %code_hash = (
'1' => [ 'Nationality at birth',
    'The nationality assigned the individual at birth.' ],
'2' => [ 'Current nationality',
    'Current nationality.' ],
'3' => [ 'Previous nationality',
    'Nationality of a person before the current nationality.' ],
);
sub get_codes { return \%code_hash; }

1;
