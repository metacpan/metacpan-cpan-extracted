package Business::EDI::CodeList::NameComponentTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3405;}
my $usage       = 'B';

# 3405  Name component type code qualifier                      [B]
# Desc: Code qualifying the type of a name component.
# Repr: an..3

my %code_hash = (
'1' => [ 'Surname',
    'The surname of an individual.' ],
'2' => [ 'Christian name',
    'Christian name.' ],
'3' => [ 'First part of a composite surname',
    'First part of a composite surname.' ],
'5' => [ 'Second part of a composite surname',
    'Second part of a composite surname.' ],
'6' => [ 'Official first Christian name',
    'First Christian name as registered in official documents.' ],
'7' => [ 'Official second Christian name',
    'Second Christian name as registered in official documents.' ],
'8' => [ 'Initial of the second Christian name',
    'Initial of the second Christian name.' ],
'9' => [ 'Official third Christian name',
    'Third Christian name as registered in official documents.' ],
'10' => [ 'Whole name',
    'Whole name, comprising an unspecified mix of components.' ],
'11' => [ 'Name suffix',
    'To identify a name suffix.' ],
'12' => [ 'Name prefix',
    'To identify a name prefix.' ],
);
sub get_codes { return \%code_hash; }

1;
