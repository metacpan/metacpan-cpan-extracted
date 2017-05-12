package Business::EDI::CodeList::PaddingMechanismCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0591";}
my $usage       = 'B';

# 0591  Padding mechanism, coded
# Desc: Padding mechanism or padding scheme applied.
# Repr: an..3

my %code_hash = (
'1' => [ 'Zero padding',
    'Message padding used for block cipher algorithms. Binary zeros are appended to the end of the message in order to make the message length an exact integer multiple of the block length. The block length is implicitly specified through the algorithm and mode of operation.' ],
'2' => [ 'PKCS #1 padding',
    'Message padding used for block cipher algorithms according to PKCS #1 (published by RSA Inc., 1993).' ],
'3' => [ 'ISO 10126 padding',
    'Message padding used for block cipher algorithms according to ISO-10126 specification.' ],
'4' => [ 'TBSS padding',
    'Message padding used for block cipher algorithms according to TBSS (Swiss standard, published by Telekurs AG, 1996).' ],
'5' => [ 'FF padding',
    'Message padding used for block cipher algorithms. Binary 255 are padded to fill a message up to a block length. The block length is implicit specified through the algorithm and mode of operation.' ],
'6' => [ 'ISO 9796 #1 padding',
    'Message padding for digital signature schemes according to ISO 9796 part 1.' ],
'7' => [ 'ISO 9796 #2 padding',
    'Message padding for digital signature schemes according to ISO 9796 part 2.' ],
'8' => [ 'ISO 9796 #3 padding',
    'Message padding for digital signature schemes according to ISO 9796 part 3.' ],
'9' => [ 'TBSS envelope padding',
    'Message padding for digital envelopes according to TBSS (Swiss standard, published by Telekurs AG, 1996)' ],
'10' => [ 'PKCS #1 envelope padding',
    'Message padding for digital envelopes according to PKCS #1 (published by RSA Inc, 1993).' ],
'11' => [ 'PKCS #1 signature padding',
    'Message padding for digital signature schemes according to PKCS #1 (published by RSA Inc, 1993).' ],
'12' => [ 'BCS signature padding',
    'Message padding for digital signature schemes according to ZKA (German standard published by ZKA 1995).' ],
'13' => [ 'OAEP',
    'Optimal Asymmetric Encryption Padding (published in IEEE P1363).' ],
'14' => [ 'RSAES-OAEP',
    'Padding mechanism specified in PKCS#1, version2, for encryption with a RSA public key.' ],
'15' => [ 'RSAES-PKCS#1-v1_5',
    'Padding mechanism specified in PKCS#1, version2, for encryption with a RSA public key.' ],
'16' => [ 'RSASA-PKCS-v1_5',
    'Padding mechanism specified in PKCS#1, version2, for digital signatures.' ],
'17' => [ 'Encryption Block Formatting',
    'Padding mechanism specified in PKCS#1, version 1.5.' ],
'18' => [ 'PKCS#5',
    'Padding mechanism specified in PKCS#5 for symmetric encryption.' ],
'19' => [ 'ANSI X9.23',
    'Padding mechanism specified in ANSI X9.23 for symmetric encryption.' ],
);
sub get_codes { return \%code_hash; }

1;
