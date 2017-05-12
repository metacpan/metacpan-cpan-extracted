package Business::EDI::CodeList::RevocationReasonCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0569";}
my $usage       = 'B';

# 0569  Revocation reason, coded
# Desc: Identification of the reason why the certificate has been
# revoked.
# Repr: an..3

my %code_hash = (
'1' => [ 'Owner key compromised',
    'The owner key linked to this certificate has been compromised.' ],
'2' => [ 'Issuer key compromised',
    'The issuer key used to generate this certificate has been compromised.' ],
'3' => [ 'Owner changed affiliation',
    'The identification details of the certificate are no longer valid.' ],
'4' => [ 'Certificate superseded',
    'This certificate has been renewed and is superseded by another certificate.' ],
'5' => [ 'Certificate terminated',
    'This certificate has reached the end of its validity period and has not been renewed.' ],
'6' => [ 'No information available',
    'This certificate is revoked but the reason is not explicit stated.' ],
'ZZZ' => [ 'Mutually agreed',
    'Mutually agreed between trading partners.' ],
);
sub get_codes { return \%code_hash; }

1;
