package Business::EDI::CodeList::SecurityServiceCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0501";}
my $usage       = 'B';

# 0501  Security service, coded
# Desc: Specification of the security service applied.
# Repr: an..3

my %code_hash = (
'1' => [ 'Non-repudiation of origin',
    "The message includes a digital signature protecting the receiver of the message from the sender's denial of having sent the message." ],
'2' => [ 'Message origin authentication',
    'The actual sender of the message cannot claim to be some other (authorised) entity.' ],
'3' => [ 'Integrity',
    'The message content is protected against the modification of data.' ],
'4' => [ 'Confidentiality',
    'The message content is protected against the unauthorised reading, copying or disclosure of its content.' ],
'5' => [ 'Non-repudiation of receipt',
    "Non-repudiation of receipt protects the sender of an object message from the receiver's denial of having received the message." ],
'6' => [ 'Receipt authentication',
    'Receipt authentication assures the sender that the message has been received by the authenticated recipient.' ],
'7' => [ 'Referenced EDIFACT structure non-repudiation of origin',
    "The referenced EDIFACT structure is secured by a digital signature protecting the receiver of the message from the sender's denial of  having sent the message." ],
'8' => [ 'Referenced EDIFACT structure origin authentication',
    'The actual sender of the referenced EDIFACT structure cannot claim to be some other (authorised) party.' ],
'9' => [ 'Referenced EDIFACT structure integrity',
    'The referenced EDIFACT structure content is protected against the modification of data.' ],
'10' => [ 'Time stamping request',
    'Ask for the EDIFACT structure to be time stamped.' ],
'11' => [ 'Entity authentication',
    'The initiator and/or responder cannot claim to be another party.' ],
'12' => [ 'Entity authentication with key establishment',
    'The initiator and/or responder cannot claim to be another party, and security keys are established.' ],
);
sub get_codes { return \%code_hash; }

1;
