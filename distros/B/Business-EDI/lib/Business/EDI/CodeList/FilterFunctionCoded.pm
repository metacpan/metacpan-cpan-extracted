package Business::EDI::CodeList::FilterFunctionCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0505";}
my $usage       = 'B';

# 0505  Filter function, coded
# Desc: Identification of the filtering function used to reversibly
# map any bit pattern on to a restricted character set.
# Repr: an..3

my %code_hash = (
'1' => [ 'No filter',
    'No filter function is used.' ],
'2' => [ 'Hexadecimal filter',
    'Hexadecimal filter.' ],
'3' => [ 'ISO 646 filter',
    'ASCII filter as described in DIS 10126-1.' ],
'4' => [ 'ISO 646 Baudot filter',
    'Baudot filter as described in DIS 10126-1.' ],
'5' => [ 'UN/EDIFACT EDA filter',
    'Filter function for UN/EDIFACT character set repertoire A as described in Part 5 of ISO 9735.' ],
'6' => [ 'UN/EDIFACT EDC filter',
    'Filter function for UN/EDIFACT character set repertoire A as described in Part 5 of ISO 9735.' ],
'7' => [ 'Base 64 filter',
    'Base 64 filter function as described in RFC 1521.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
