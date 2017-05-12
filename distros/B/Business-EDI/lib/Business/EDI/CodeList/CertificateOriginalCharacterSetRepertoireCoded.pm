package Business::EDI::CodeList::CertificateOriginalCharacterSetRepertoireCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0543";}
my $usage       = 'B';

# 0543  Certificate original character set repertoire, coded
# Desc: Identification of the character set repertoire used to create
# the certificate it was signed.
# Repr: an..3

my %code_hash = (
'1' => [ 'UN/ECE level A',
    'As defined in the basic code table of ISO 646 with the exceptions of lower case letters, alternative graphic character allocations and national or application- oriented graphic character allocations.' ],
'2' => [ 'UN/ECE level B',
    'As defined in the basic code table of ISO 646 with the exceptions of alternative graphic character allocations and national or application-oriented graphic character allocations.' ],
'3' => [ 'UN/ECE level C',
    'As defined in ISO 8859-1 : Information processing - Part 1: Latin alphabet No. 1.' ],
'4' => [ 'UN/ECE level D',
    'As defined in ISO 8859-2 : Information processing - Part 2: Latin alphabet No. 2.' ],
'5' => [ 'UN/ECE level E',
    'As defined in ISO 8859-5 : Information processing - Part 5: Latin/Cyrillic alphabet.' ],
'6' => [ 'UN/ECE level F',
    'As defined in ISO 8859-7 : Information processing - Part 7: Latin/Greek alphabet.' ],
'7' => [ 'UN/ECE level G',
    'As defined in ISO 8859-3 : Information processing - Part 3: Latin alphabet.' ],
'8' => [ 'UN/ECE level H',
    'As defined in ISO 8859-4 : Information processing - Part 4: Latin alphabet.' ],
'9' => [ 'UN/ECE level I',
    'As defined in ISO 8859-6 : Information processing - Part 6: Latin/Arabic alphabet.' ],
'10' => [ 'UN/ECE level J',
    'As defined in ISO 8859-8 : Information processing - Part 8: Latin/Hebrew alphabet.' ],
'11' => [ 'UN/ECE level K',
    'As defined in ISO 8859-9 : Information processing - Part 9: Latin alphabet.' ],
'12' => [ 'UN/ECE level X',
    'Code extension technique as defined by ISO 2022 utilising the escape techniques in accordance with ISO 2375.' ],
'13' => [ 'UN/ECE level Y',
    'ISO 10646-1 octet without code extension technique.' ],
'14' => [ 'UN/ECE level W',
    'ISO 10646-1 octet with code extension technique to support UTF-8 (UCS Transformation Format, 8 bit) encoding.' ],
);
sub get_codes { return \%code_hash; }

1;
