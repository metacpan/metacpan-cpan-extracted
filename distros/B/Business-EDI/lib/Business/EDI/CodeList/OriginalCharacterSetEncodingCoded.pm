package Business::EDI::CodeList::OriginalCharacterSetEncodingCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0507";}
my $usage       = 'B';

# 0507  Original character set encoding, coded
# Desc: Identification of the character set in which the secured
# EDIFACT structure was encoded when security mechanisms were
# applied.
# Repr: an..3

my %code_hash = (
'1' => [ 'ASCII 7 bit',
    'ASCII 7 bit code.' ],
'2' => [ 'ASCII 8 bit',
    'ASCII 8 bit code.' ],
'3' => [ 'Code page 850 (IBM PC Multinational)',
    'Encoding schema for the repertoire as defined by the code page.' ],
'4' => [ 'Code page 500 (EBCDIC Multinational No. 5)',
    'Encoding schema for the repertoire as defined by the code page.' ],
'5' => [ 'UCS-2',
    'Universal Multiple-Octet Coded Character Set (UCS) two- octet per character encoding schema as defined in ISO/IEC 10646-1.' ],
'6' => [ 'UCS-4',
    'Universal Multiple-Octet Coded Character Set (UCS) four- octet per character encoding schema as defined in ISO/IEC 10646-1.' ],
'7' => [ 'UTF-8',
    'UCS Transformation Format 8 (UTF-8) multi-octet (of length one to six octets) per character encoding schema as defined in ISO/IEC 10646-1, Annex R.' ],
'8' => [ 'UTF-16',
    'UCS Transformation Format 16 (UTF-16) two-octet per character encoding schema as defined in ISO/IEC 10646-1, Annex Q.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
