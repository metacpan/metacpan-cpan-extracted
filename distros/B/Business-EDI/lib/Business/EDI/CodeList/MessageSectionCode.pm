package Business::EDI::CodeList::MessageSectionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {1049;}
my $usage       = 'B';

# 1049  Message section code                                    [B]
# Desc: Code specifying a section of a message.
# Repr: an..3

my %code_hash = (
'1' => [ 'Heading section',
    'The section of the message being referenced is the header.' ],
'2' => [ 'Detail section',
    'The section of the message being referenced is the detail.' ],
'5' => [ 'Multiple sections',
    'Multiple sections of the message are being referenced.' ],
'6' => [ 'Summary section',
    'The section of the message being referenced is the summary.' ],
'7' => [ 'Sub-line item',
    'The section of the message being referenced refers to the sub-line item.' ],
'8' => [ 'Commercial heading section of CUSDEC',
    'Group 7 to 14 of CUSDEC message.' ],
'9' => [ 'Commercial line detail section of CUSDEC',
    'Group 15 to 22 of CUSDEC message.' ],
'10' => [ 'Customs item detail section of CUSDEC',
    'Group 23 to 33 of CUSDEC message.' ],
'11' => [ 'Customs sub-item detail section of CUSDEC',
    'Group 34 and 35 of CUSDEC message.' ],
);
sub get_codes { return \%code_hash; }

1;
