package Business::EDI::CodeList::QualificationApplicationAreaCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9035;}
my $usage       = 'B';

# 9035  Qualification application area code                     [B]
# Desc: Code specifying the application area of a
# qualification.
# Repr: an..3

my %code_hash = (
'1' => [ 'Public administration sector',
    'Public administration sector.' ],
'2' => [ 'Agricultural sector',
    'Agricultural sector.' ],
'3' => [ 'Automotive sector',
    'Automotive sector.' ],
'4' => [ 'Transport sector',
    'Transport sector.' ],
'5' => [ 'Finance sector',
    'Finance sector.' ],
'6' => [ 'Tourism sector',
    'Tourism sector.' ],
'7' => [ 'Construction sector',
    'Construction sector.' ],
);
sub get_codes { return \%code_hash; }

1;
