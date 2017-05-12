package Business::EDI::CodeList::FreeTextFormatCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {4447;}
my $usage       = 'B';

# 4447  Free text format code                                   [B]
# Desc: Code specifying the format of free text.
# Repr: an..3

my %code_hash = (
'1' => [ 'Centre',
    'The associated text is centred in the available space.' ],
'2' => [ 'Left',
    'The associated text item is aligned flush left in the available space.' ],
'3' => [ 'Right',
    'The associated text is aligned flush right in the available space.' ],
'4' => [ 'Justified',
    'The associated text is justified in the available space.' ],
'5' => [ 'Preceded by one blank line',
    'The text is to be preceded by one blank line.' ],
'6' => [ 'Preceded by two blank lines',
    'The text is to be preceded by two blank lines.' ],
'7' => [ 'Preceded by three blank lines',
    'The text is to be preceded by three blank lines.' ],
'8' => [ 'Continuation',
    'The text is a continuation of preceding text.' ],
'9' => [ 'New page',
    'The text is to begin on a new page.' ],
'10' => [ 'End text',
    'The text is the final section of the preceding text.' ],
'11' => [ 'New line',
    'The text is to begin a new line.' ],
);
sub get_codes { return \%code_hash; }

1;
