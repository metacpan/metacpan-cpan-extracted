package Business::EDI::CodeList::PackagingDangerLevelCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8339;}
my $usage       = 'B';

# 8339  Packaging danger level code                             [B]
# Desc: Code specifying the level of danger for which the
# packaging must cater.
# Repr: an..3

my %code_hash = (
'1' => [ 'Great danger',
    'Packaging meeting criteria to pack hazardous materials with great danger. Group I according to IATA/IMDG/ADR/RID regulations.' ],
'2' => [ 'Medium danger',
    'Packaging meeting criteria to pack hazardous materials with medium danger. Group II according to IATA/IDMG/ADR/RID regulations.' ],
'3' => [ 'Minor danger',
    'Packaging meeting criteria to pack hazardous materials with minor danger. Group III according to IATA/IDMG/ADR/RID regulations.' ],
'4' => [ 'Not assigned',
    'No packaging danger level has been assigned.' ],
);
sub get_codes { return \%code_hash; }

1;
