package Business::EDI::CodeList::DataFormatDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1503;}
my $usage       = 'C';

# 1503  Data format description code                            [C]
# Desc: Code specifying the data format.
# Repr: an..3

my %code_hash = (
'1' => [ 'ASCII',
    'Code to identify the ASCII format (American Standard Code II).' ],
'2' => [ 'EBCDIC',
    'Code to identify the EBCDIC format (Extended Binary Character Decimal Interchange Code).' ],
'3' => [ 'Binary',
    'Code to identify a binary format.' ],
'4' => [ 'Analogue',
    'Code to identify an analogue format.' ],
);
sub get_codes { return \%code_hash; }

1;
