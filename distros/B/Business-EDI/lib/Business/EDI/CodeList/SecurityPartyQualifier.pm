package Business::EDI::CodeList::SecurityPartyQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0577";}
my $usage       = 'B';

# 0577  Security party qualifier
# Desc: Identification of the role of the security party.
# Repr: an..3

my %code_hash = (
'1' => [ 'Message sender',
    'Identifies the party which generates the security parameters of the message (i.e. security originator).' ],
'2' => [ 'Message receiver',
    'Identifies the party which verifies the security parameters of the message (i.e. security recipient).' ],
'3' => [ 'Certificate owner',
    'Identifies the party which owns the certificate.' ],
'4' => [ 'Authenticating party',
    'Party which certifies that the document (i.e. the certificate) is authentic.' ],
);
sub get_codes { return \%code_hash; }

1;
