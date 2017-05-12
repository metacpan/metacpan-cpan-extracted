package Business::EDI::CodeList::EditMaskRepresentationCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9031;}
my $usage       = 'B';

# 9031  Edit mask representation code                           [B]
# Desc: Code specifying the representation of the edit mask.
# Repr: an..3

my %code_hash = (
'1' => [ 'COBOL picture',
    'The associated edit mask is represented as a COBOL picture statement.' ],
'2' => [ 'C printf',
    "The associated edit mask is represented as a C 'printf' format." ],
'3' => [ 'FORTRAN format',
    'The associated edit mask is represented as a FORTRAN format statement.' ],
'4' => [ 'Unix(tm) regular expression',
    'The associated edit mask is represented as a Unix(tm) regular expression.' ],
);
sub get_codes { return \%code_hash; }

1;
