package Business::EDI::CodeList::SubstitutionConditionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4457;}
my $usage       = 'B';

# 4457  Substitution condition code                             [B]
# Desc: Code specifying the conditions under which
# substitution may take place.
# Repr: an..3

my %code_hash = (
'1' => [ 'No substitution allowed',
    'Notice to supplier to fill order exactly as specified.' ],
'2' => [ 'Supply any binding if edition ordered not available',
    'Indicates that substitute bindings are acceptable if the edition of a book originally ordered is unavailable.' ],
'3' => [ 'Supply paper binding if edition ordered not available',
    'Indicates that a paper back edition of a book is acceptable if the edition ordered is unavailable.' ],
'4' => [ 'Supply cloth binding if edition ordered not available',
    'Indicates that the cloth bound edition of a book is acceptable if the edition ordered is unavailable.' ],
'5' => [ 'Supply library binding if edition ordered not available',
    'Indicates that a library binding of a book is acceptable if the edition ordered is unavailable.' ],
'6' => [ 'Equivalent item substitution',
    'Indicates that an item of the same value and performance may be substituted for the item specified.' ],
'7' => [ 'Alternate item substitution allowed',
    'Indicates that an item of equal or greater value and performance may be substituted for the item specified.' ],
'ZZZ' => [ 'Mutually defined',
    'A code reserved for special trading partner requirements when pre-defined codes do not exist.' ],
);
sub get_codes { return \%code_hash; }

1;
