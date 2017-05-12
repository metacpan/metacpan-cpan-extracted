package Business::EDI::CodeList::DefinitionExtentCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {9025;}
my $usage       = 'B';

# 9025  Definition extent code                                  [B]
# Desc: Code specifying the extent of a definition.
# Repr: an..3

my %code_hash = (
'1' => [ 'Begin',
    'To specify the beginning of a definition.' ],
'2' => [ 'End',
    'To specify the end of a definition.' ],
'3' => [ 'Use',
    'To specify use of a definition.' ],
);
sub get_codes { return \%code_hash; }

1;
