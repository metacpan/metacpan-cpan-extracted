package Business::EDI::CodeList::SecurityStatusCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0567";}
my $usage       = 'B';

# 0567  Security status, coded
# Desc: Identification of the security element (key or certificate,
# for instance) status.
# Repr: an..3

my %code_hash = (
'1' => [ 'Valid',
    'The security element is valid.' ],
'2' => [ 'Revoked',
    'The security element has been revoked.' ],
'3' => [ 'Unknown',
    'The status of the security element is unknown.' ],
'4' => [ 'Discontinued',
    'The security element should not be used for ?????' ],
'5' => [ 'Alert',
    'The security element has been put on alert, but is not revoked yet.' ],
'6' => [ 'Expired',
    'The validity period of the security element is expired.' ],
);
sub get_codes { return \%code_hash; }

1;
