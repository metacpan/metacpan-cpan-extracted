package Business::EDI::CodeList::MessageVersionNumber;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0052";}
my $usage       = 'B';

# 0052  Message version number
# Desc: Version number of a message type.
# Repr: an..3

my %code_hash = (
'1' => [ 'Status 1 version',
    'Message approved and issued as a status 1 (trial) message. (Valid for directories published after March 1990 and prior to March 1993).' ],
'2' => [ 'Status 2 version',
    'Message approved and issued as a status 2 (formal recommendation) message. (Valid for directories published after March 1990 and prior to March 1993).' ],
'4' => [ 'Service message, version 4',
    'Service messages approved and issued as a part of ISO 9735/Version 4, for use with that version of the syntax.' ],
'1.' => [ 'For earlier versions of the UN/EDIFACT CONTRL message,',
    'each published by the UN as a stand-alone message, the version number to be used is specified in the message documentation.' ],
'88' => [ '1988 version',
    'Message approved and issued in the 1988 release of the UNTDID (United Nations Trade Data Interchange Directory) as a status 2 (formal recommendation) message.' ],
'89' => [ '1989 version',
    'Message approved and issued in the 1989 release of the UNTDID (United Nations Trade Data Interchange Directory) as a status 2 (formal recommendation) message.' ],
'90' => [ '1990 version',
    'Message approved and issued in the 1990 release of the UNTDID (United Nations Trade Data Interchange Directory) as a status 2 (formal recommendation) message.' ],
'D' => [ 'Draft version/UN/EDIFACT Directory',
    'Message approved and issued as a draft message (Valid for directories published after March 1993 and prior to March 1997). Message approved as a standard message (Valid for directories published after March 1997).' ],
'S' => [ 'Standard version',
    'Message approved and issued as a standard message. (Valid for directories published after March 1993 and prior to March 1997).' ],
);
sub get_codes { return \%code_hash; }

1;
