package Business::EDI::CodeList::ServiceSegmentTagCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0135";}
my $usage       = 'B';

# 0135  Service segment tag, coded
# Desc: Code identifying a service segment.
# Repr: an..3

my %code_hash = (
'UCD' => [ 'Data element error indication',
    'To identify an erroneous stand-alone, composite or component data element, and to identify the nature of the error.' ],
'UCF' => [ 'Group response',
    'To identify a group in the subject interchange and to indicate acknowledgement or rejection (action taken) of the UNG and UNE segments, and to identify any error related to these segments. It can also identify errors related to the USA, USC, USD, USH, USR, UST, or USU security segments when they appear at the group level. Depending on the action code, it may also indicate the action taken on the messages and packages within that group.' ],
'UCI' => [ 'Interchange response',
    'To identify the subject interchange, to indicate interchange receipt, to indicate acknowledgement or rejection (action taken) of the UNA, UNB and UNZ segments, and to identify any error related to these segments. It can also identify errors related to the USA, USC, USD, USH, USR, UST, or USU security segments when they appear at the interchange level. Depending on the action code, it may also indicate the action taken on the groups, messages, and packages within that interchange.' ],
'UCM' => [ 'Message/package response',
    "To identify a message or package in the subject interchange, and to indicate that message's or package's acknowledgement or rejection (action taken), and to identify any error related to the UNH, UNT, UNO, and UNP segments. It can also identify errors related to the USA, USC, USD, USH, USR, UST, or USU security segments when they appear at the message or package level." ],
'UCS' => [ 'Segment error indication',
    'To identify either a segment containing an error or a missing segment, and to identify any error related to the complete segment.' ],
'UGH' => [ 'Anti-collision segment group header',
    'To head, identify and specify an anti-collision segment group.' ],
'UGT' => [ 'Anti-collision segment group trailer',
    'To end and check the completeness of an anti-collision segment group.' ],
'UIB' => [ 'Interactive interchange header',
    'To head and identify an interchange.' ],
'UIH' => [ 'Interactive message header',
    'To head, identify and specify a message.' ],
'UIR' => [ 'Interactive status',
    'To report the status of the dialogue.' ],
'UIT' => [ 'Interactive message trailer',
    'To end and check the completeness of a message.' ],
'UIZ' => [ 'Interactive interchange trailer',
    'To end and check the completeness of an interchange.' ],
'UNB' => [ 'Interchange header',
    'To identify an interchange.' ],
'UNE' => [ 'Group trailer',
    'To end and check the completeness of a group.' ],
'UNG' => [ 'Group header',
    'To head, identify and specify a group of messages and/or packages, which may be used for internal routing and which may contain one or more message types and/or packages.' ],
'UNH' => [ 'Message header',
    'To head, identify and specify a message.' ],
'UNO' => [ 'Object header',
    'To head, identify and specify an object.' ],
'UNP' => [ 'Object trailer',
    'To end and check the completeness of an object.' ],
'UNS' => [ 'Section control',
    'To separate header, detail and summary sections of a message.' ],
'UNT' => [ 'Message trailer',
    'To end and check the completeness of a message.' ],
'UNZ' => [ 'Interchange trailer',
    'To end and check the completeness of an interchange.' ],
'USA' => [ 'Security algorithm',
    'To identify a security algorithm, the technical usage made of it, and to contain the technical parameters required.' ],
'USB' => [ 'Secured data identification',
    'To contain details related to the AUTACK.' ],
'USC' => [ 'Certificate',
    'To convey the public key and the credentials of its owner.' ],
'USD' => [ 'Data encryption header',
    'To specify size (i.e. length of data in octets of bits) of encrypted data following the segment terminator of this segment.' ],
'USE' => [ 'Security message relation',
    'To specify the relation to earlier security messages, such as response to a particular request, or request for a particular answer.' ],
'USF' => [ 'Key management function',
    'To specify the type of key management function and the status of a corresponding key or certificate.' ],
'USH' => [ 'Security header',
    'To specify a security mechanism applied to a EDIFACT structure (i.e.: either message/package, group or interchange).' ],
'USL' => [ 'Security list status',
    'To specify the status of security objects, such as keys or certificates to be delivered in a list, and the corresponding list parameters.' ],
'USR' => [ 'Security result',
    'To contain the result of the security mechanisms.' ],
'UST' => [ 'Security trailer',
    'To establish a link between security header and security trailer segment groups.' ],
'USU' => [ 'Data encryption trailer',
    'To provide a trailer for the encrypted data.' ],
'USX' => [ 'Security references',
    'To refer to the secured EDIFACT structure and its associated date and time.' ],
'USY' => [ 'Security on references',
    'To identify the applicable header, and to contain the security result and/or to indicate the possible cause of security rejection for the referred value.' ],
);
sub get_codes { return \%code_hash; }

1;
