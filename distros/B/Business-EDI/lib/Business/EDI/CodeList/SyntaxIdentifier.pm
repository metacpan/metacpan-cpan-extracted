package Business::EDI::CodeList::SyntaxIdentifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0001";}
my $usage       = 'B';

# 0001  Syntax identifier
# Desc: Coded identification of the agency controlling the syntax, and
# of the character repertoire used in an interchange.
# Repr: a4

my %code_hash = (
'UNOA' => [ 'UN/ECE level A',
    'As defined in the basic code table of ISO 646 with the exceptions of lower case letters, alternative graphic character allocations and national or application- oriented graphic character allocations.' ],
'UNOB' => [ 'UN/ECE level B',
    'As defined in the basic code table of ISO 646 with the exceptions of alternative graphic character allocations and national or application-oriented graphic character allocations.' ],
'UNOC' => [ 'UN/ECE level C',
    'As defined in ISO/IEC 8859-1 : Information technology - Part 1: Latin alphabet No. 1.' ],
'UNOD' => [ 'UN/ECE level D',
    'As defined in ISO/IEC 8859-2 : Information technology - Part 2: Latin alphabet No. 2.' ],
'UNOE' => [ 'UN/ECE level E',
    'As defined in ISO/IEC 8859-5 : Information technology - Part 5: Latin/Cyrillic alphabet.' ],
'UNOF' => [ 'UN/ECE level F',
    'As defined in ISO 8859-7 : Information processing - Part 7: Latin/Greek alphabet.' ],
'UNOG' => [ 'UN/ECE level G',
    'As defined in ISO/IEC 8859-3 : Information technology - Part 3: Latin alphabet No. 3.' ],
'UNOH' => [ 'UN/ECE level H',
    'As defined in ISO/IEC 8859-4 : Information technology - Part 4: Latin alphabet No. 4.' ],
'UNOI' => [ 'UN/ECE level I',
    'As defined in ISO/IEC 8859-6 : Information technology - Part 6: Latin/Arabic alphabet.' ],
'UNOJ' => [ 'UN/ECE level J',
    'As defined in ISO/IEC 8859-8 : Information technology - Part 8: Latin/Hebrew alphabet.' ],
'UNOK' => [ 'UN/ECE level K',
    'As defined in ISO/IEC 8859-9 : Information technology - Part 9: Latin alphabet No. 5.' ],
'UNOL' => [ 'UN/ECE level L',
    'As defined in ISO/IEC 8859-15 : Information technology - Part 15: Latin alphabet No. 9.' ],
'UNOW' => [ 'UN/ECE level W',
    'ISO 10646-1 octet with code extension technique to support UTF-8 (UCS Transformation Format, 8 bit) encoding.' ],
'UNOX' => [ 'UN/ECE level X',
    'Code extension technique as defined by ISO 2022 utilising the escape techniques in accordance with ISO 2375.' ],
'UNOY' => [ 'UN/ECE level Y',
    'ISO 10646-1 octet without code extension technique.' ],
);
sub get_codes { return \%code_hash; }

1;
