package Business::EDI::CodeList::DateAndTimeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0517";}
my $usage       = 'B';

# 0517  Date and time qualifier
# Desc: Specification of the type of date and time.
# Repr: an..3

my %code_hash = (
'1' => [ 'Security Timestamp',
    'Security timestamp of the secured message.' ],
'2' => [ 'Certificate generation date and time',
    'Identifies the date and time of generation of the certificate by the Certification Authority.' ],
'3' => [ 'Certificate start of validity period',
    'Identifies the date and time from which the certificate must be considered valid.' ],
'4' => [ 'Certificate end of validity period',
    'Identifies the date and time until which the certificate must be considered valid.' ],
'5' => [ 'EDIFACT structure generation date and time',
    'Date and time of generation of the secured EDIFACT structure.' ],
'6' => [ 'Certificate revocation date and time',
    'Identifies the date and time of revocation of the certificate by the Certification Authority.' ],
'7' => [ 'Key generation date and time',
    'Identifies the date and time of generation of the key(s).' ],
);
sub get_codes { return \%code_hash; }

1;
