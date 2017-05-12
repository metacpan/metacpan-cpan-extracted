package Business::EDI::CodeList::UseOfAlgorithmCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0523";}
my $usage       = 'B';

# 0523  Use of algorithm, coded
# Desc: Specification of the usage made of the algorithm.
# Repr: an..3

my %code_hash = (
'1' => [ 'Owner hashing',
    'Specifies that the algorithm is used by the message sender to compute the hash function on the message (as in the case of Integrity or Non-repudiation of Origin identified in the security function qualifier of USH).' ],
'2' => [ 'Owner symmetric',
    'Specifies that the algorithm is used by the message sender either for integrity, confidentiality, or message origin authentication (specified by security service, coded in USH).' ],
'3' => [ 'Issuer signing',
    'Specifies that the algorithm is used by the Certificate Issuer (CA) to sign the hash result computed on the certificate.' ],
'4' => [ 'Issuer hashing',
    'Specifies that the algorithm is used by the Certificate Issuer (CA) to compute the hash result on the certificate.' ],
'5' => [ 'Owner enciphering',
    'Specifies that the algorithm is used by the message sender to encrypt a symmetric key.' ],
'6' => [ 'Owner signing',
    'Specifies that the algorithm is used by the message sender to sign either the hash result computed on the message or the symmetric keys.' ],
'7' => [ 'Owner enciphering or signing',
    'Specifies that the algorithm may be used by the message sender either to encrypt a symmetric key or sign the hash result computed on the  message. This value may only be used in a USA segment within a USC segment group. When encrypting a symmetric key a receiver certificate shall be used. When signing a hash result a sender certificate shall be used.' ],
'8' => [ 'Owner compressing',
    'Specifies that the algorithm is used by the message sender to compress the data before (encryption and) submission.' ],
'9' => [ 'Owner compression integrity',
    'Specifies that the algorithm is used by the message sender on the compressed data before (encryption and) submission. The integrity value is used to verify the contents of the compressed text before expansion.' ],
'10' => [ 'Key agreement',
    'Specifies that the algorithm is used by the initiator and responder to agree a secret key.' ],
);
sub get_codes { return \%code_hash; }

1;
