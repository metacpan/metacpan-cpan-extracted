package Business::EDI::CodeList::MaritalStatusDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {3479;}
my $usage       = 'C';

# 3479  Marital status description code                         [C]
# Desc: Code specifying the marital status of a person.
# Repr: an..3

my %code_hash = (
'1' => [ 'Unmarried and never been married',
    'Person is unmarried and has never been married.' ],
'2' => [ 'Married',
    'Person is married.' ],
'3' => [ 'Unmarried and been married before',
    'Person is unmarried but has been married before.' ],
'4' => [ 'Separated',
    'Person is still married but living apart from spouse.' ],
'5' => [ 'Widow or widower',
    'Person is a widow or widower.' ],
'6' => [ 'Unknown',
    'The marital status is unknown.' ],
);
sub get_codes { return \%code_hash; }

1;
