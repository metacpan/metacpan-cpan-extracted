package Business::EDI::CodeList::SyntaxErrorCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0085";}
my $usage       = 'B';

# 0085  Syntax error, coded
# Desc: A code indicating the error detected.
# Repr: an..3

my %code_hash = (
'2' => [ 'Syntax version or level not supported',
    'Notification that the syntax version and/or level is not supported by the recipient.' ],
'7' => [ 'Interchange recipient not actual recipient',
    'Notification that the Interchange recipient (S003) is different from the actual recipient.' ],
'12' => [ 'Invalid value',
    'Notification that the value of a stand-alone data element, composite data element or component data element does not conform to the relevant specifications for the value.' ],
'13' => [ 'Missing',
    'Notification that a mandatory (or otherwise required) service or user segment, data element, composite data element or component data element is missing.' ],
'14' => [ 'Value not supported in this position',
    'Notification that the recipient does not support use of the specific value of an identified stand-alone data element, composite data element or component data element in the position where it is used. The value may be valid according to the relevant specifications and may be supported if it is used in another position.' ],
'15' => [ 'Not supported in this position',
    'Notification that the recipient does not support use of the segment type, stand-alone data element type, composite data element type or component data element type in the identified position.' ],
'16' => [ 'Too many constituents',
    'Notification that the identified segment contained too many data elements or that the identified composite data element contained too many component data elements.' ],
'17' => [ 'No agreement',
    'No agreement exists that allows receipt of an interchange, group, message, or package with the value of the identified stand-alone data element, composite data element or component data element.' ],
'18' => [ 'Unspecified error',
    'Notification that an error has been identified, but the nature of the error is not reported.' ],
'20' => [ 'Character invalid as service character',
    'Notification that a character advised in UNA is invalid as service character.' ],
'21' => [ 'Invalid character(s)',
    'Notification that one or more character(s) used in the interchange is not a valid character as defined by the syntax identifier indicated in UNB. The invalid character is part of the referenced-level, or followed immediately after the identified part of the interchange.' ],
'22' => [ 'Invalid service character(s)',
    'Notification that the service character(s) used in the interchange is not a valid service character as advised in UNA or not one of the default service characters. If the code is used in UCS or UCD, the invalid character followed immediately after the identified part of the interchange.' ],
'23' => [ 'Unknown Interchange sender',
    'Notification that the Interchange sender (S002) is unknown.' ],
'24' => [ 'Too old',
    'Notification that the received interchange or group is older than a limit specified in an IA or determined by the recipient.' ],
'25' => [ 'Test indicator not supported',
    'Notification that test processing can not be performed for the identified interchange, group, message, or package.' ],
'26' => [ 'Duplicate detected',
    'Notification that a possible duplication of a previously received interchange, group, message, or package has been detected. The earlier transmission may have been rejected.' ],
'28' => [ 'References do not match',
    'Notification that the control reference in UNB, UNG, UNH, UNO, USH or USD does not match the one in UNZ, UNE, UNT, UNP, UST or USU, respectively.' ],
'29' => [ 'Control count does not match number of instances received',
    'Notification that the number of groups, messages, or segments does not match the number given in UNZ, UNE, UNT or UST, or that the length of an object or of encrypted data is not equal to the length stated in the UNO, UNP, USD, or USU.' ],
'30' => [ 'Groups and messages/packages mixed',
    'Notification that groups have been mixed with messages/packages outside of groups in the interchange.' ],
'32' => [ 'Lower level empty',
    'Notification that the interchange does not contain any messages, packages, or groups, or a group does not contain any messages or packages.' ],
'33' => [ 'Invalid occurrence outside message, package, or group',
    'Notification of an invalid segment or data element in the interchange, between messages or between packages or between groups. Rejection is reported at the level above.' ],
'35' => [ 'Too many data element or segment repetitions',
    'Notification that a stand-alone data element, composite data element or segment is repeated too many times.' ],
'36' => [ 'Too many segment group repetitions',
    'Notification that a segment group is repeated too many times.' ],
'37' => [ 'Invalid type of character(s)',
    'Notification that one or more numeric characters are used in an alphabetic (component) data element or that one or more alphabetic characters are used in a numeric (component) data element.' ],
'39' => [ 'Data element too long',
    'Notification that the length of the data element received exceeded the maximum length specified in the data element description.' ],
'40' => [ 'Data element too short',
    'Notification that the length of the data element received is shorter than the minimum length specified in the data element description.' ],
'45' => [ 'Trailing separator',
    'Notification of one of the following: - the last character before the segment terminator is a data element separator or a component data element separator or a repeating data element separator, or - the last character before a data element separator is a component data element separator or a repeating data element separator.' ],
'46' => [ 'Character set not supported',
    'Notification that one or more characters used are not in the character set defined by the syntax identifier, or the character set identified by the escape sequence for the code extension technique is not supported by the recipient.' ],
'47' => [ 'Envelope functionality not supported',
    'Notification that the envelope structure encountered is not supported by the recipient.' ],
'48' => [ 'Dependency condition violated',
    'Notification that an error condition has occurred as the result of a dependency condition violation.' ],
);
sub get_codes { return \%code_hash; }

1;
