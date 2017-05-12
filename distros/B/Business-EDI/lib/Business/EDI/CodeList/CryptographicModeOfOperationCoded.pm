package Business::EDI::CodeList::CryptographicModeOfOperationCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0525";}
my $usage       = 'B';

# 0525  Cryptographic mode of operation, coded
# Desc: Specification of the mode of operation used for the algorithm.
# Repr: an..3

my %code_hash = (
'1' => [ 'ECB',
    'DES modes of operation, Electronic Code Book; FIPS Pub 81 (1981); ANSI X3.106; IS 8372 (64 bits); ISO 10116 (n- bits).' ],
'2' => [ 'CBC',
    'DES modes of operation, Cipher Block Chaining; FIPS Pub 81 (1981); ANSI X3.106; IS 8372 (64 bits); ISO 10116 (n- bits).' ],
'3' => [ 'CFB1',
    'DES modes of operation, Cipher feedback; FIPS Pub 81 (1981); ANSI X3.106; IS 8372 (64 bits); ISO 10116 (n- bits).' ],
'4' => [ 'CFB8',
    'DES modes of operation, Cipher feedback; FIPS Pub 81 (1981); ANSI X3.106; IS 8372 (64 bits); ISO 10116 (n- bits).' ],
'5' => [ 'OFB',
    'DES modes of operation; FIPS Pub 81 (1981); IS 8372 (64 bits); ISO 10116 (n-bits).' ],
'16' => [ 'DSMR',
    'Digital Signature scheme giving Message Recovery. ISO 9796.' ],
'17' => [ 'CFB64',
    'DES mode of operation, cipher feedback; ISO 10116 (n- bits).' ],
'23' => [ 'TCBC',
    'TDEA mode of operation, Cipher Block Chaining, ANSI X9.52.' ],
'24' => [ 'TCBC-I',
    'TDEA mode of operation, Cipher Block Chaining - Interleaved, ANSI X9.52.' ],
'25' => [ 'TCFB1',
    'TDEA mode of operation, Cipher Feedback - 1 bit feedback, ANSI X9.52.' ],
'26' => [ 'TCFB8',
    'TDEA mode of operation, Cipher Feedback - 8 bit feedback, ANSI X9.52.' ],
'27' => [ 'TCFB64',
    'TDEA mode of operation, Cipher Feedback - 64 bit feedback, ANSI X9.52.' ],
'28' => [ 'TCFB1-P',
    'TDEA mode of operation, Cipher Feedback Pipelined - 1 bit feedback, ANSI X9.52.' ],
'29' => [ 'TCFB8-P',
    'TDEA mode of operation, Cipher Feedback Pipelined - 8 bit feedback, ANSI X9.52.' ],
'30' => [ 'TCFB64-P',
    'TDEA mode of operation, Cipher Feedback Pipelined - 64 bit feedback, ANSI X9.52.' ],
'31' => [ 'TOFB',
    'TDEA mode of operation, Output Feedback Mode, ANSI X9.52.' ],
'32' => [ 'TOFB-P',
    'TDEA mode of operation, Output Feedback Mode Pipelined, ANSI X9.52.' ],
'33' => [ 'TCBCM',
    'TDEA mode of operation, Cipher Block Chaining with output feedback Masking, ANSI X9.52.' ],
'34' => [ 'TCBCM-I',
    'TDEA mode of operation, Cipher Block Chaining with output feedback Masking Interleaved, ANSI X9.52.' ],
'35' => [ 'TECB',
    'TDEA mode of operation, Electronic Cookbook Mode, ANSI X9.52.' ],
'36' => [ 'CTS',
    'RC5 mode of operation, Cipher Text Stealing, Published in RCF 2040.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
