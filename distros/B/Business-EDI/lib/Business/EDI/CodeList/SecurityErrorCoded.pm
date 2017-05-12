package Business::EDI::CodeList::SecurityErrorCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0571";}
my $usage       = 'B';

# 0571  Security error, coded
# Desc: Identifies the security error causing the rejection of the
# EDIFACT structure.
# Repr: an..3

my %code_hash = (
'1' => [ 'Wrong authenticator',
    'The validation is wrong.' ],
'2' => [ 'Wrong certificate',
    'The certificate is wrong.' ],
'3' => [ 'Certification path',
    'The certification path is incomplete. Cannot verify.' ],
'4' => [ 'Algorithm not supported',
    'The algorithm is not supported.' ],
'5' => [ 'Hashing method not supported',
    'The hashing method is not supported.' ],
'6' => [ 'Protocol error',
    'The stated protocol has not been followed.' ],
'7' => [ 'Security expected but not present',
    'It was expected the user message would be secured (eg using integrated message security or the AUTACK message in authentication mode), but this was not present or received in the expected time period.' ],
'8' => [ 'Security parameters do not match those expected',
    'The parameters specifying the applied security do not match those expected (eg from an interchange agreement).' ],
);
sub get_codes { return \%code_hash; }

1;
