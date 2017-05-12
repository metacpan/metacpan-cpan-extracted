package Business::EDI::CodeList::KeyManagementFunctionQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0579";}
my $usage       = 'B';

# 0579  Key management function qualifier
# Desc: Specification of the type of key management function.
# Repr: an..3

my %code_hash = (
'101' => [ 'Registration submission',
    'Submission of information for registration.' ],
'102' => [ 'Asymmetric key pair request',
    'Request a trusted party to generate an asymmetric key pair.' ],
'110' => [ 'Certification request',
    'Request certification of credentials and public key.' ],
'111' => [ 'Certificate renewal request',
    'Request to extend the validity period of the current valid key, whose certificate is about to expire.' ],
'112' => [ 'Certificate replacement request',
    'Request to replace the current certificate by a new one with a different public key (and possibly other information).' ],
'121' => [ 'Certificate (path) retrieval request',
    'Request the delivery of an existing (valid or revoked) certificate, with path details where appropriate.' ],
'123' => [ 'Certificate list retrieval request',
    'Request full or partial list of certificate.' ],
'124' => [ 'Certificate status request',
    'Request current status of a given certificate.' ],
'125' => [ 'Certificate validation request',
    'Request the CA to validate an existing certificate.' ],
'126' => [ 'Certificate delivery request',
    'Request the CA to deliver a (valid or revoked) certificate to a list of recipients known to the CA or specified elsewhere.' ],
'130' => [ 'Revocation request',
    "Request revocation of a party's certificate." ],
'131' => [ 'Alert request',
    "Request to put a party's certificate on alert." ],
'140' => [ 'Revocation list request',
    'Request full or partial list of revoked certificates.' ],
'150' => [ 'Symmetric key request',
    'Request the delivery of symmetric keys.' ],
'151' => [ 'Symmetric key discontinuation request',
    'Request discontinuation of symmetric key.' ],
'152' => [ 'Asymmetric key discontinuation request',
    'Request discontinuation of asymmetric key.' ],
'221' => [ 'Certificate delivery',
    'Delivery of an existing (valid or revoked) certificate.' ],
'222' => [ 'Certificate path delivery',
    'Delivery of a path.' ],
'224' => [ 'Certificate status notice',
    'Notice of current status of a given certificate.' ],
'225' => [ 'Certificate validation notice',
    'Notice of validation of an existing certificate.' ],
'231' => [ 'Revocation confirmation',
    "Confirmation of revocation of a party's certificate." ],
'251' => [ 'Symmetric key delivery',
    'Delivery of symmetric keys.' ],
'252' => [ 'Discontinuation acknowledgement',
    'Acknowledgement of the requested discontinuation.' ],
);
sub get_codes { return \%code_hash; }

1;
