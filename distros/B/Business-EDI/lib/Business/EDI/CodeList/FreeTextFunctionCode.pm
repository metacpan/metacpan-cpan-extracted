package Business::EDI::CodeList::FreeTextFunctionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4453;}
my $usage       = 'B';

# 4453  Free text function code                                 [B]
# Desc: Code specifying the function of free text.
# Repr: an..3

my %code_hash = (
'1' => [ 'Text for subsequent use',
    'The occurrence of this text does not affect message processing.' ],
'2' => [ 'Text replacing missing code',
    'Text description of a coded data item for which there is no currently available code.' ],
'3' => [ 'Text for immediate use',
    'Text must be read before actioning message.' ],
'4' => [ 'No action required',
    'Pass text on to later recipient.' ],
'5' => [ 'Header',
    'Indicates that the text is to be taken as a header.' ],
'6' => [ 'Numbered paragraph',
    'Indicates that the text starts a new numbered paragraph.' ],
'7' => [ 'Paragraph',
    'Indicates that the text is a paragraph.' ],
);
sub get_codes { return \%code_hash; }

1;
