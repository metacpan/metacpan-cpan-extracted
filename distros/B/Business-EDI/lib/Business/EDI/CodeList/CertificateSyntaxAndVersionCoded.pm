package Business::EDI::CodeList::CertificateSyntaxAndVersionCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0545";}
my $usage       = 'B';

# 0545  Certificate syntax and version, coded
# Desc: Coded identification of the syntax and version used to create
# the certificate.
# Repr: an..3

my %code_hash = (
'1' => [ 'EDIFACT version 4',
    'ISO 9735 version 4.' ],
'2' => [ 'EDIFACT version 3',
    'ISO 9735 version 3.' ],
'3' => [ 'X.509',
    'ISO/IEC 9594-8, ITU X.509 key/certificate reference.' ],
'4' => [ 'PGP',
    'PGP (Pretty Good Privacy) based format key/certificate reference.' ],
'5' => [ 'EDI 5 v1.4',
    'Version 1.4 of the EDI 5 certificate (French national standard).' ],
);
sub get_codes { return \%code_hash; }

1;
