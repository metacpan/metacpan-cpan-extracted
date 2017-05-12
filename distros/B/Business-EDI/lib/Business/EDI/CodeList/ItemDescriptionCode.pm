package Business::EDI::CodeList::ItemDescriptionCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {7009;}
my $usage       = 'C';

# 7009  Item description code                                   [C]
# Desc: Code specifying an item.
# Repr: an..17

my %code_hash = (
'1' => [ 'Bold text',
    'Displayed text is bold.' ],
'2' => [ 'Dimmed text',
    'Displayed text is dimmed.' ],
'3' => [ 'Italic',
    'Displayed text is italicised.' ],
'4' => [ 'Normal text',
    'Displayed text is normal.' ],
'5' => [ 'Reversed text',
    'Displayed text foreground and background colours are reversed.' ],
);
sub get_codes { return \%code_hash; }

1;
